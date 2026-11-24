"""Installer checks: local files only, no Claude process or model calls."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class InstallTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="readme-loop install ")
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.dest = self.home / ".claude/skills/readme-loop"

    def run_install(self, *args, script=None):
        return subprocess.run(
            ["bash", str(script or ROOT / "scripts/install.sh"), *args],
            cwd=self.home, env={**os.environ, "HOME": str(self.home)},
            capture_output=True, text=True,
        )

    def test_complete_copy_without_private_or_draft_files(self):
        result = self.run_install("--claude")
        self.assertEqual(result.returncode, 0, result.stderr)
        for entry in ("SKILL.md", "README.md", "references", "scripts", "tests"):
            source = ROOT / entry
            files = [source] if source.is_file() else [p for p in source.rglob("*") if p.is_file()]
            for path in files:
                relative = path.relative_to(ROOT)
                self.assertEqual(path.read_bytes(), (self.dest / relative).read_bytes(), str(relative))
        self.assertFalse((self.dest / ".wtha").exists())
        self.assertFalse((self.dest / "ARTICLE-DRAFT.md").exists())

    def test_pi_and_codex_paths_and_overwrite_protection(self):
        for flag, folder in (("--pi", ".pi/agent/skills"), ("--codex", ".agents/skills")):
            with self.subTest(flag=flag):
                dest = self.home / folder / "readme-loop"
                result = self.run_install(flag)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual((dest / "SKILL.md").read_bytes(), (ROOT / "SKILL.md").read_bytes())
                self.assertEqual((dest / "scripts/loop.sh").read_bytes(), (ROOT / "scripts/loop.sh").read_bytes())
                (dest / "SKILL.md").write_text("owner changes")
                self.assertNotEqual(self.run_install(flag).returncode, 0)
                self.assertEqual((dest / "SKILL.md").read_text(), "owner changes")

    def test_existing_installation_is_preserved(self):
        self.dest.mkdir(parents=True)
        marker = self.dest / "SKILL.md"
        marker.write_text("owner changes")
        result = self.run_install("--claude")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(marker.read_text(), "owner changes")
        self.assertEqual(list(self.dest.iterdir()), [marker])

    def test_symlink_is_not_followed(self):
        self.dest.parent.mkdir(parents=True)
        target = self.home / "owner-data"
        target.mkdir()
        self.dest.symlink_to(target, target_is_directory=True)
        self.assertNotEqual(self.run_install("--claude").returncode, 0)
        self.assertEqual(list(target.iterdir()), [])

    def test_help_and_invalid_arguments_do_not_install(self):
        self.assertEqual(self.run_install("--help").returncode, 0)
        for args in ((), ("--unknown",), ("--claude", "extra")):
            self.assertEqual(self.run_install(*args).returncode, 2)
        self.assertFalse(self.dest.parent.exists())

    def test_missing_package_does_not_create_destination(self):
        incomplete = self.home / "incomplete/scripts"
        incomplete.mkdir(parents=True)
        script = incomplete / "install.sh"
        script.write_bytes((ROOT / "scripts/install.sh").read_bytes())
        self.assertNotEqual(self.run_install("--claude", script=script).returncode, 0)
        self.assertFalse(self.dest.exists())


if __name__ == "__main__":
    unittest.main()
