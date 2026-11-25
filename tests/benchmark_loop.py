#!/usr/bin/env python3
"""Optional local runner-overhead benchmark; no models, commits or network.

Usage: python3 tests/benchmark_loop.py [path/to/loop.sh]
Runs 40 passing no-op tasks three times per check mode in a temporary repo.
This measures orchestration overhead, not application-stage performance.
"""
import json
from pathlib import Path
import statistics
import subprocess
import sys
import tempfile
import time

runner = Path(sys.argv[1] if len(sys.argv) > 1 else
              Path(__file__).resolve().parents[1] / "scripts/loop.sh").resolve()
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    subprocess.run(["git", "init", "-q", directory], check=True)
    (root / ".gitignore").write_text(".loop/\n")
    (root / "tasks.json").write_text(json.dumps({"tasks": [
        {"id": f"T{i}", "title": "metadata benchmark",
         "test": 'printf "PASS\\n"', "expect": ["PASS"], "tier": "normal"}
        for i in range(40)
    ]}))
    for mode in ("--check-once", "--check"):
        durations = []
        for _ in range(3):
            start = time.monotonic()
            subprocess.run(["bash", str(runner), mode], cwd=root,
                           stdout=subprocess.DEVNULL, check=True)
            durations.append(time.monotonic() - start)
        print(f"{mode}: median {statistics.median(durations):.3f}s; "
              f"runs {[round(value, 3) for value in durations]}", flush=True)
