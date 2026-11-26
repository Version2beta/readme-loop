#!/usr/bin/env python3
"""Run trusted acceptance commands once, serially. Not a sandbox or model loop."""
import argparse
import math
import os
from pathlib import Path
import signal
import subprocess
import sys
import time


class Interrupted(Exception):
    def __init__(self, signum):
        self.signum = signum


def positive_seconds(value):
    try:
        seconds = float(value)
    except ValueError:
        raise argparse.ArgumentTypeError("timeout must be a positive finite number")
    if not math.isfinite(seconds) or seconds <= 0:
        raise argparse.ArgumentTypeError("timeout must be a positive finite number")
    return seconds


def stop_group(process):
    """Do not leave same-group children running when their shell exits first."""
    try:
        os.killpg(process.pid, signal.SIGTERM)
    except ProcessLookupError:
        pass
    try:
        process.wait(timeout=1)
    except subprocess.TimeoutExpired:
        pass
    try:
        os.killpg(process.pid, signal.SIGKILL)
    except ProcessLookupError:
        pass
    process.wait()


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Run each trusted Bash command once; stop at the first failure.",
        epilog="Not a sandbox. No models, commits or discards; commands keep their own side effects.",
    )
    parser.add_argument("--cwd", type=Path, default=Path.cwd(), help="project directory")
    parser.add_argument("--timeout", type=positive_seconds, default=300,
                        help="per-command seconds (default: 300)")
    parser.add_argument("commands", nargs="+", help="quoted commands; use -- before them")
    args = parser.parse_args(argv)
    if os.name != "posix":
        parser.error("a POSIX system with Bash is required")
    if not args.cwd.is_dir():
        parser.error("--cwd must be an existing directory")
    if any(not command.strip() for command in args.commands):
        parser.error("commands must not be blank")

    spawning = False
    pending_signal = None

    def interrupt(signum, _frame):
        nonlocal pending_signal
        if spawning:
            # Finish obtaining the child handle before interruption can unwind.
            pending_signal = signum
        else:
            raise Interrupted(signum)

    previous = {sig: signal.signal(sig, interrupt) for sig in (signal.SIGINT, signal.SIGTERM)}
    try:
        for index, command in enumerate(args.commands, 1):
            label = f"check {index}/{len(args.commands)}"
            print(f"RUN  {label}: {command}", flush=True)
            start = time.monotonic()
            process = None
            try:
                spawning = True
                try:
                    process = subprocess.Popen(["bash", "-c", command], cwd=args.cwd,
                                               start_new_session=True)
                finally:
                    spawning = False
                if pending_signal is not None:
                    raise Interrupted(pending_signal)
                rc = process.wait(timeout=args.timeout)
            except subprocess.TimeoutExpired:
                for sig in previous:
                    signal.signal(sig, signal.SIG_IGN)
                stop_group(process)
                print(f"TIMEOUT {label} after {args.timeout:g}s", file=sys.stderr, flush=True)
                return 124
            except Interrupted as exc:
                if process is not None:
                    # A second termination signal must not interrupt cleanup.
                    for sig in previous:
                        signal.signal(sig, signal.SIG_IGN)
                    stop_group(process)
                print(f"INTERRUPTED {label} (signal {exc.signum})", file=sys.stderr, flush=True)
                return 128 + exc.signum
            except OSError as exc:
                print(f"ERROR {label}: {exc}", file=sys.stderr, flush=True)
                return 2
            if rc < 0:
                rc = 128 - rc
            result = "PASS" if rc == 0 else "FAIL"
            print(f"{result} {label} ({time.monotonic() - start:.3f}s; exit {rc})", flush=True)
            if rc:
                return rc
        return 0
    except Interrupted as exc:
        return 128 + exc.signum
    finally:
        for sig, handler in previous.items():
            signal.signal(sig, handler)


if __name__ == "__main__":
    sys.exit(main())
