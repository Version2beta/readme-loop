"""Exercise the published kit example's protection EREs, not review semantics."""
import json
from pathlib import Path
import re
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]


class ProtectionExampleTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        text = (ROOT / "references/kit-format.md").read_text()
        example = re.search(r"```json\n(.*?)\n```", text, re.S).group(1)
        cls.pattern = "|".join(json.loads(example)["protected"])

    def protected(self, path):
        result = subprocess.run(
            ["grep", "-E", self.pattern], input=path + "\n",
            capture_output=True, text=True,
        )
        self.assertIn(result.returncode, (0, 1), result.stderr)
        return result.returncode == 0

    def test_contract_and_verification_paths_are_protected(self):
        for path in ("README.md", "module/README.md", "module/behavior_test.go",
                     "testdata/output.golden", "verification/fake_os.go"):
            with self.subTest(path=path):
                self.assertTrue(self.protected(path))

    def test_production_design_and_progress_remain_writable(self):
        # The former ^internal/event/ example froze a whole production package.
        for path in ("internal/event/model.go", "internal/event/new_strategy.go",
                     "internal/linux/access.go", "cmd/tool/main.go", "PROGRESS.md"):
            with self.subTest(path=path):
                self.assertFalse(self.protected(path))


if __name__ == "__main__":
    unittest.main()
