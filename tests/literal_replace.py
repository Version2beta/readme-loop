#!/usr/bin/env python3
"""Exact first-occurrence byte replacement for disposable regression sources."""
import os
import sys


def replace_first(source, old, new):
    if not old or old not in source:
        raise ValueError("mutation anchor absent or empty")
    return source.replace(old, new, 1)


def main(argv=None):
    args = sys.argv[1:] if argv is None else argv
    if len(args) != 2:
        print("expected OLD and NEW arguments", file=sys.stderr)
        return 2
    try:
        result = replace_first(sys.stdin.buffer.read(), os.fsencode(args[0]), os.fsencode(args[1]))
    except ValueError as exc:
        print("ASSERTION FAILED:", exc, file=sys.stderr)
        return 1
    sys.stdout.buffer.write(result)
    return 0


if __name__ == "__main__":
    sys.exit(main())
