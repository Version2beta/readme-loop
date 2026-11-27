# Legacy v0.1 kit format

Historical reference for the old runner's schema and acceptance semantics.
[The current skill](../SKILL.md) does not require a kit.

## Layout

```
SPEC.md          binding behavior for this stage
PROMPT.md        what the coder is told every iteration
PROGRESS.md      the coder's running notes (three lines per attempt)
tasks.json       ordered tasks and the loop's per-kit settings
scripts/loop.sh  copied unchanged from this skill
README.md        exact commands to apply the kit and run the loop
.gitignore       must contain .loop/
...              minimal writable stubs, protected tests and fixtures
```

An overlay for a later stage contains only what it adds or replaces, plus
the full `tasks.json`.

## Protected-surface acceptance gate

The kit author owns the specification and the judge; the implementation agent
owns the implementation. Include a completed [protected-surface review](protected-surface.md)
in a protected section of `SPEC.md` before acceptance, handoff, or any separately
authorized commit. Revisit it for overlays and changes to the judge.
Protect verification and contracts; leave production design and code writable
unless an explicit contract or minimal deterministic verification seam requires
otherwise. Prefer black-box behavioral checks. Tests that import internals can
constrain architecture even when no production source is protected; account for
those interfaces too. Do not copy reference production code into starting stubs.
A successful private reference does not establish an unambiguous specification
or sufficient judge. Preserve failing-stub/passing-reference checks and challenge
incorrect behavior independently; never reduce coverage to simplify protection.

## tasks.json

```json
{
  "format": "gofmt -w .",
  "format_check": "test -z \"$(gofmt -l .)\"",
  "check": "go vet ./...",
  "protected": ["(^|/)README\\.md$", "_test\\.go$", "^testdata/", "^verification/"],
  "tasks": [
    {
      "id": "T1",
      "title": "Implement slug.Slugify",
      "test": "go test -v ./slug -run '^TestSlugify$' -count=1",
      "expect": ["^--- PASS: TestSlugify \\(.*\\)$"],
      "tier": "normal"
    },
    {
      "id": "T9",
      "title": "Whole tree: formatted, checked, every test green",
      "test": "test -z \"$(gofmt -l .)\" && go vet ./... && go test -v ./... -count=1",
      "expect": ["^--- PASS: TestSlugify \\(.*\\)$", "^--- PASS: TestWrapLines \\(.*\\)$", "^--- PASS: TestRun \\(.*\\)$"],
      "tier": "normal"
    }
  ]
}
```

| Field | Meaning |
| --- | --- |
| `format` | Optional formatter, run after protected paths are restored and before judging. Failure discards the attempt. |
| `format_check` | Optional non-writing format check. Must exit 0 in the judge, including `--check` and `--check-once`. |
| `check` | Optional non-writing whole-kit check (vet, lint, type check). Must exit 0 in the judge, including `--check` and `--check-once`. |
| `protected` | Extended regular expressions for paths the coder may not change: contracts, tests, fixtures, golden outputs, verification infrastructure, and specifically justified production exceptions recorded in the protected-surface review. A "complete; do not change" label alone does not justify production protection. The loop always adds `tasks.json`, `PROMPT.md`, `SPEC.md` and itself. |
| `tasks[].test` | One shell command, run from the repository root. Must exit 0 and print every expected line on stdout. Stderr is logged separately and cannot satisfy expectations. |
| `tasks[].expect` | Required, nonempty list of nonempty extended regular expressions (grep ERE). Each must match a complete stdout line (`grep -xE`), not a substring. An empty/missing list or invalid expression is a kit error naming the task. |
| `tasks[].tier` | `normal` starts on the cheap model; `hard` starts on the strong one. |

The loop hands the coder the first task that does not pass, so order
matters: the whole-tree task goes last, and an overlay replaces the old
whole-tree task rather than leaving it in the middle.

`pass_marker` is obsolete: kits containing it are refused, not reinterpreted.
Migrate each old test name to a full-line expression in `tasks[].expect`.
JSON doubles regex backslashes: the expression `\(` is written `\\(`.

### Worked expectations

Check output on the reference implementation with the installed runner before
shipping. Disable color so escape sequences cannot change the expected line.

**Go:** `go test -run '^TestEnqueue$' -v ./...`

```json
"expect": ["^--- PASS: TestEnqueue \\(.*\\)$"]
```

This matches the complete `--- PASS: TestEnqueue (0.00s)` line. Exit 0
without that line fails, as does a diagnostic containing the text.

**pytest:** `pytest -rA --color=no tests/test_enqueue.py::test_enqueue`

```json
"expect": ["^PASSED tests/test_enqueue\\.py::test_enqueue$"]
```

`-rA` supplies the exact `PASSED tests/test_enqueue.py::test_enqueue` line
in the short test summary. Pin one node, with no parameters in this example.

**ExUnit:** `mix test test/dwrr/enqueue_test.exs`

For versions that print `12 tests, 0 failures`:

```json
"expect": ["^12 tests, 0 failures$"]
```

The count is part of the expectation: losing a test fails the judge. This
pattern rejects all failure counts other than zero, and all skip/exclusion
suffixes. Older runners can append `, 1 excluded` or `, 1 skipped`; if those
are intentional, record their exact counts too rather than accepting an
arbitrary suffix.

Installed Elixir **1.20.4 / OTP 29** was checked with a disposable Mix
project and this single-file command. It uses a newer summary:
`Result: 12 passed` (no failures), or, with one skipped and one excluded test,
`Result: 12 passed, 1 skipped, 1 excluded`. For that version use:

```json
"expect": ["^Result: 12 passed$"]
```

Or, only when those skip/exclusion counts are intended:

```json
"expect": ["^Result: 12 passed, 1 skipped, 1 excluded$"]
```

Do not combine formats with a loose `.*` suffix: failures and changed counts
must be rejected. Configure ExUnit with `colors: [enabled: false]` if needed.

### Owner settings and judge order

A kit must not set `CHEAP_CMD`, `STRONG_CMD` or `STRONGEST_CMD`; these are
owner environment overrides with pinned defaults in the unchanged loop.
An explicitly empty override refuses startup and names the setting.

Task selection runs each test at most once in order, without format or kit
checks, and reuses the failing output in the prompt. Each attempt runs the
coder, restores protected paths, runs `format`, restores protected paths again,
and records the tree. It then judges `format_check`, the task test, every
earlier task test, and `check`. If judge commands change the tree, the attempt
fails with "judge commands modified the tree". On success the loop commits
without further file changes, disables commit hooks that could rewrite the
judged tree, asserts HEAD's tree matches it, and asserts a clean working tree.
On failure it saves `PROGRESS.md` additions to `.loop/notes.<task-id>` before
discarding all attempt changes. Saved notes appear in the next prompt for any
task under "Notes from discarded attempts" and are not committed. Logs remain
in `.loop/`. Check commands must not modify source files. `--check` uses the
same judge but never runs the coder or formatter. `--check-once [ID...]` runs
`format_check`, the selected tasks (default all) and `check` once each, for
fast verification of a fixed tree; the full `--check` remains stage acceptance.

Every formatter, format check, task test (including diagnostic probes), and
kit check has an owner-set `JUDGE_TIMEOUT` (default 300 seconds). A timeout
fails the attempt and logs the command. `timeout` or `gtimeout` is mandatory.
Before coding, tracked changes and non-ignored untracked files are refused;
untracked files are listed. New files created during an attempt can be committed.
The exact coder command is recorded per attempt in `.loop/loop.log` and in
every loop commit's `Coder-Command:` trailer.

## PROMPT.md (starting point)

```
You are implementing one task in this repository. Work from the files only.

1. Read SPEC.md and PROGRESS.md.
2. Do the task below and nothing else. Own the production design and code
   within SPEC.md's approved contract and reviewed interface constraints.
   Internal names, signatures, packages and algorithms are yours to change
   as needed for the task while preserving earlier required behavior.
3. Never edit tests, fixtures, SPEC.md, tasks.json, PROMPT.md, the loop, or
   any file marked "complete; do not change". Changes there are reverted.
4. Run the task's test command.
5. Append three lines to PROGRESS.md: the task id, what you did, what is
   left or what blocked you.
6. Stop. Do not commit. The loop judges and commits.
```

## README.md must say

- How to apply the kit (a fresh repository, or `unzip -o` over the previous
  stage's branch) and confirm earlier tasks still pass.
- The exact model commands, for example
  `CHEAP_CMD='…' STRONG_CMD='…' STRONGEST_CMD='…' scripts/loop.sh`.
- Where the loop leaves things: commits on the branch, `.loop/` for prompts
  and coder logs, `STOP` naming the task that ran out of attempts.
