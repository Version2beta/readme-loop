"""The mutation preparer is literal, byte-preserving, and rejects stale anchors."""
from pathlib import Path
import subprocess
import sys
import unittest

HELPER = Path(__file__).with_name("literal_replace.py")


class LiteralReplaceTests(unittest.TestCase):
    def run_replace(self, source, old, new):
        return subprocess.run([sys.executable, str(HELPER), old, new], input=source,
                              capture_output=True, timeout=3)

    def test_only_first_literal_occurrence_is_replaced(self):
        result = self.run_replace(b"prefix a*[x]\\b middle a*[x]\\b suffix", "a*[x]\\b", "new$[]")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, b"prefix new$[] middle a*[x]\\b suffix")

    def test_preserves_multibyte_binary_and_newline_content(self):
        source = ("é🙂\n" * 20000).encode() + b"\x00ANCHOR\xff\n"
        result = self.run_replace(source, "ANCHOR", "replacement\nline")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, source.replace(b"ANCHOR", b"replacement\nline", 1))

    def test_missing_or_empty_anchor_cannot_be_a_successful_noop(self):
        for anchor in ("absent", ""):
            with self.subTest(anchor=anchor):
                result = self.run_replace(b"unchanged", anchor, "new")
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(result.stdout, b"")
                self.assertIn(b"MUTATION PREPARATION FAILED", result.stderr)
                self.assertNotIn(b"ASSERTION FAILED", result.stderr)


if __name__ == "__main__":
    unittest.main()
