"""Malformed kits must fail before commands or state creation. No real coders."""
import copy
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

RUNNER = Path(__file__).resolve().parents[1] / "scripts/loop.sh"
BASE = {"tasks": [{"id": "T1", "test": "touch executed; echo PASS",
                   "expect": ["PASS"], "tier": "normal"}]}


class RunnerConfigTests(unittest.TestCase):
    def reject(self, kit, args=("--check-once",)):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "tasks.json").write_text(json.dumps(kit))
            env = dict(os.environ, CHEAP_CMD="touch executed",
                       STRONG_CMD="touch executed", STRONGEST_CMD="touch executed")
            result = subprocess.run(["bash", str(RUNNER), *args], cwd=root,
                                    env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 1, result.stderr)
            self.assertIn("loop:", result.stderr)
            self.assertFalse((root / "executed").exists())
            self.assertFalse((root / ".loop").exists())

    def test_rejects_malformed_task_lists(self):
        for tasks in (None, [], {}, [None], ["task"]):
            with self.subTest(tasks=tasks):
                self.reject({"tasks": tasks})

    def test_rejects_invalid_commands_and_metadata(self):
        for field, value in (("test", None), ("test", ""), ("test", " \n\t"),
                             ("test", []), ("id", 1), ("tier", "expensive"),
                             ("title", {})):
            with self.subTest(field=field, value=value):
                kit = copy.deepcopy(BASE)
                kit["tasks"][0][field] = value
                self.reject(kit)

    def test_rejects_duplicate_ids(self):
        kit = copy.deepcopy(BASE)
        kit["tasks"] *= 2
        self.reject(kit)

    def test_rejects_invalid_optional_commands(self):
        for field in ("format", "format_check", "check"):
            with self.subTest(field=field):
                self.reject(dict(BASE, **{field: ["echo PASS"]}))

    def test_rejects_invalid_protection(self):
        for patterns in (".*", [1], [""], ["["]):
            with self.subTest(patterns=patterns):
                self.reject(dict(BASE, protected=patterns))

    def test_rejects_unknown_or_extra_arguments(self):
        for args in (("--unknown",), ("--check", "T1"), ("",)):
            with self.subTest(args=args):
                self.reject(BASE, args)


if __name__ == "__main__":
    unittest.main()
