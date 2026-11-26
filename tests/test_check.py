"""Behavioral tests for the optional single-pass helper; no models or real kits."""
import os
import runpy
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import time
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
CHECK = ROOT / "scripts/check.py"


@unittest.skipUnless(os.name == "posix", "helper requires POSIX")
class CheckTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="readme-loop checks ")
        self.addCleanup(self.temp.cleanup)
        self.cwd = Path(self.temp.name)

    def run_check(self, *args, env=None):
        return subprocess.run([sys.executable, str(CHECK), *args], cwd=self.cwd,
                              capture_output=True, text=True, timeout=8, env=env)

    def test_each_command_runs_once_in_order_without_a_kit_or_git(self):
        result = self.run_check("--cwd", str(self.cwd), "--",
                                "printf A >> trace", "printf B >> trace", "printf C >> trace")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.cwd / "trace").read_text(), "ABC")
        self.assertEqual(result.stdout.count("PASS check"), 3)
        self.assertEqual({p.name for p in self.cwd.iterdir()}, {"trace"})

    def test_stops_at_first_failure_and_retains_exit_status(self):
        result = self.run_check("--", "exit 7", "touch should-not-run")
        self.assertEqual(result.returncode, 7)
        self.assertIn("FAIL check 1/2", result.stdout)
        self.assertFalse((self.cwd / "should-not-run").exists())

    def test_stdout_and_stderr_keep_their_streams(self):
        result = self.run_check("--", "printf output; printf diagnostic >&2")
        self.assertEqual(result.returncode, 0)
        # The first line labels the shell command; inspect its actual output.
        command_output = result.stdout.split("\n", 1)[1]
        self.assertIn("output", command_output)
        self.assertNotIn("diagnostic", command_output)
        self.assertEqual(result.stderr, "diagnostic")

    def test_shell_commands_preserve_newlines_and_inherited_cwd(self):
        result = self.run_check("--", "printf A > trace\nprintf B >> trace")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.cwd / "trace").read_text(), "AB")

    def test_timeout_stops_later_checks(self):
        result = self.run_check("--timeout", "0.1", "--", "sleep 10", "touch later")
        self.assertEqual(result.returncode, 124, result.stderr)
        self.assertIn("TIMEOUT", result.stderr)
        self.assertFalse((self.cwd / "later").exists())

    def test_timeout_stops_children_even_when_the_shell_exits_on_term(self):
        result = self.run_check("--timeout", "0.1", "--",
                                "trap 'exit 0' TERM; (sleep 0.6; touch survived) & wait")
        self.assertEqual(result.returncode, 124, result.stderr)
        time.sleep(0.7)
        self.assertFalse((self.cwd / "survived").exists())

    def test_cleanup_verifies_zombies_and_keeps_leader_identity_until_last_signal(self):
        module = runpy.run_path(str(CHECK))
        process = mock.Mock(pid=12345)
        def signal_group(pgid, signum):
            process.wait.assert_not_called()
            if signum == signal.SIGKILL:
                raise PermissionError("fixture EPERM")
        status = subprocess.CompletedProcess([], 0, "12345 Z\n")
        with mock.patch.object(sys, "platform", "darwin"), \
             mock.patch.object(os, "killpg", side_effect=signal_group), \
             mock.patch.object(os, "waitid", return_value=object(), create=True), \
             mock.patch.object(time, "sleep"), \
             mock.patch.object(subprocess, "run", return_value=status):
            module["stop_group"](process)
        process.wait.assert_called_once_with()

    def test_cleanup_does_not_suppress_permission_failure_for_live_or_unknown_group(self):
        for code, output in ((0, "12345 S\n"), (0, "12345 Z\n12345 S\n"),
                             (0, "999 Z\n"), (0, ""), (1, "")):
            with self.subTest(code=code, output=output):
                module = runpy.run_path(str(CHECK))
                process = mock.Mock(pid=12345)
                status = subprocess.CompletedProcess([], code, output)
                with mock.patch.object(sys, "platform", "darwin"), \
                     mock.patch.object(os, "killpg", side_effect=[None, PermissionError("fixture EPERM")]), \
                     mock.patch.object(os, "waitid", return_value=object(), create=True), \
                     mock.patch.object(time, "sleep"), \
                     mock.patch.object(subprocess, "run", return_value=status):
                    with self.assertRaises(PermissionError):
                        module["stop_group"](process)
                process.wait.assert_not_called()

    def test_timeout_kills_a_command_that_ignores_term(self):
        result = self.run_check("--timeout", "0.1", "--",
                                "trap '' TERM; while :; do sleep 1; done")
        self.assertEqual(result.returncode, 124, result.stderr)

    def test_interruption_stops_the_active_command_and_later_checks(self):
        process = subprocess.Popen(
            [sys.executable, str(CHECK), "--", "touch ready; sleep 10", "touch later"],
            cwd=self.cwd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
            start_new_session=True,
        )
        try:
            deadline = time.monotonic() + 4
            while not (self.cwd / "ready").exists() and process.poll() is None:
                self.assertLess(time.monotonic(), deadline, "command did not start")
                time.sleep(0.01)
            process.send_signal(signal.SIGTERM)
            stdout, stderr = process.communicate(timeout=3)
            self.assertEqual(process.returncode, 143, stdout + stderr)
            self.assertIn("INTERRUPTED", stderr)
            self.assertFalse((self.cwd / "later").exists())
        finally:
            if process.poll() is None:
                process.kill()
            process.communicate(timeout=3)

    def test_signal_during_spawn_does_not_lose_the_child_handle(self):
        # Deliver a real signal after creation but before Popen returns to main.
        probe = f'''
import os, runpy, signal, subprocess
module = runpy.run_path({str(CHECK)!r})
original = subprocess.Popen
children = []
def spawn(*args, **kwargs):
    child = original(*args, **kwargs)
    children.append(child)
    os.kill(os.getpid(), signal.SIGTERM)
    return child
subprocess.Popen = spawn
try:
    rc = module['main'](['--', 'sleep 10'])
    print('RESULT', rc, 'REAPED', children[0].poll() is not None)
finally:
    for child in children:
        if child.poll() is None:
            os.killpg(child.pid, signal.SIGKILL)
            child.wait()
'''
        result = subprocess.run([sys.executable, "-I", "-c", probe], cwd=self.cwd,
                                capture_output=True, text=True, timeout=5)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("RESULT 143 REAPED True", result.stdout)

    def test_child_exit_codes_can_overlap_helper_exit_codes(self):
        for code in (2, 124):
            with self.subTest(code=code):
                result = self.run_check("--", f"exit {code}")
                self.assertEqual(result.returncode, code)
                self.assertIn("FAIL check", result.stdout)
                self.assertNotIn("TIMEOUT", result.stderr)

    def test_rejects_invalid_limits_before_running_commands(self):
        for value in ("0", "-1", "nan", "inf", "nonsense"):
            with self.subTest(value=value):
                result = self.run_check("--timeout", value, "--", "touch executed")
                self.assertEqual(result.returncode, 2)
                self.assertFalse((self.cwd / "executed").exists())

    def test_rejects_blank_commands_before_running_any_command(self):
        for command in ("", " \n\t"):
            with self.subTest(command=command):
                result = self.run_check("--", "touch executed", command)
                self.assertEqual(result.returncode, 2)
                self.assertFalse((self.cwd / "executed").exists())

    def test_requires_commands_and_an_existing_directory(self):
        self.assertEqual(self.run_check().returncode, 2)
        result = self.run_check("--cwd", str(self.cwd / "missing"), "--", "touch executed")
        self.assertEqual(result.returncode, 2)
        self.assertFalse((self.cwd / "executed").exists())

    def test_missing_bash_is_reported_without_running_a_command(self):
        result = self.run_check("--", "touch executed", env={**os.environ, "PATH": str(self.cwd)})
        self.assertEqual(result.returncode, 2)
        self.assertIn("ERROR", result.stderr)
        self.assertFalse((self.cwd / "executed").exists())

    def test_command_signal_death_has_shell_style_status(self):
        self.assertEqual(self.run_check("--", "kill -TERM $$").returncode, 143)

    def test_exit_zero_is_not_claimed_to_prove_test_collection(self):
        # Deliberately no tests. Qualification belongs to the acceptance owner.
        result = self.run_check("--", "true")
        self.assertEqual(result.returncode, 0)
        self.assertNotIn("tests passed", result.stdout)

    def test_help_has_no_workspace_side_effects(self):
        result = self.run_check("--help")
        self.assertEqual(result.returncode, 0)
        self.assertIn("not a sandbox", result.stdout.lower())
        self.assertEqual(list(self.cwd.iterdir()), [])


if __name__ == "__main__":
    unittest.main()
