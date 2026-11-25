# Bounded development review

## Authority, scope and independent review

Branch `overnight-reliability-performance`, base `a1f9daa`. Local edits, tests
and commits only: no push, release, dependency install, installed-skill change,
production or SIE access, agent, model/API or CLI model call, and no nested job.
`ARTICLE-DRAFT.md` is untracked, was not read for this work and is not added.

**Independent review: not performed.** No reviewer was authorized, so every
finding below is self-review and not evidence of independent verification. Do
not merge to `main` until an independent reviewer has checked the diff in
`scripts/loop.sh`, `scripts/test_loop.sh` and the `SKILL.md` contract edits,
with the attacks listed under "Review requests".

The earlier statements that the owner's $2.18, 25-minute, 20/20, 12-attempt
and corrective-run figures were unverified are now superseded for the named
reports below. Those reports were read, not rerun.

## Baseline evidence (historical, read from the named reports)

Project: drift (the application under test; not the toy fixture). The figures
below are what the reports state. I did not verify them against provider
billing, and no new model run was made.

| Run | Source | Cost (report) | Elapsed (UTC) | Tasks | Coder attempts | Retries | Outcome |
| --- | --- | ---: | --- | ---: | ---: | ---: | --- |
| run1 | stage1-list, kit `f8f224f` | $2.18 | 07:52:40 to 08:17:51 (25 m 11 s; coder wall 1413 s) | 20/20 | 12 | 0 | Full `--check` passed; Opus never used |
| run2 | corrective kit `b242c9c` on stage1-corrective | $0.23 | 08:40:55 to 08:44:41 (3 m 46 s) | 26/26 | 6 | 0 | Full `--check` passed; commit `c4f3e75` (C06) |

Cross-checks in the logs: run1's `loop.log` has 12 `Coder-Command` and 12
`passed` lines, and no timeout, STOP, failed-attempt or tree-change lines.
run2's `loop.log` has 6 `Coder-Command` lines. Other run2 log lines were not
checked.

## Runner investigation

Each item was reproduced first in disposable fixtures under `/tmp` with the
unmodified runner (`a1f9daa`), then rechecked against the fix.

1. **Custom `TASKS` path protection: defect, fixed.** The task file name was
   interpolated into the protection ERE. With `TASKS=tasks+v2.json`, the `+`
   is a quantifier and the file was not protected. With `TASKS=./tasks.json`,
   git's `tasks.json` never matched `./`. A coder that edited the kit's
   `expect` and passed had the edited kit committed, exit 0. The default name
   was protected (exit 2). The fix protects the task file by exact,
   repository-relative name (`./` stripped; absolute paths inside the
   repository resolved through `pwd -P`), with no regex.

2. **Check-only mutation: defect, fixed.** A check that rewrote a tracked file
   made `--check` and `--check-once` exit 0, although the contract says checks
   must not mutate the accepted tree and attempt mode already rejects it.
   Both check-only modes now compare working-tree snapshots taken through a
   temporary index in `.loop/`, so the user's staged state is untouched. A
   change exits 1 and logs `judge commands modified the tree`. The mutated
   file is left in place, as the log says.

3. **Judge and coder timeouts: defect, fixed.** A judge that ignored SIGTERM
   ran past `JUDGE_TIMEOUT=1` until my outer 12-second deadline stopped it, so
   judging was unbounded despite the "all judge commands are bounded" rule.
   Judge and coder commands now get `timeout -k 5` (fixed grace, not an owner
   setting). The same judge is killed after 6 seconds, logged as
   `killed (exit 137 ...)`. Exit 137 is shell-reported, and the shell also
   prints `Killed: 9` to the runner's stderr. That line is cosmetic.

4. **Restart and attempt accounting: observed, not changed.** The attempt
   counter increments before the coder starts. In a fixture, interrupting the
   runner during a coder that had made no tree changes left `attempts=1`. The
   clean-start gate passed, and the restart ran `attempt 2/4` with the strong
   command. So an interrupted attempt consumes budget and escalates. Whether it
   should count is a contract choice; I left it unchanged. Refusal of a dirty
   tree after interruption is refused by the clean-start gate; existing tests
   cover that refusal (`untracked` in `scripts/test_loop.sh`, and the dirty-tree
   case in `tests/run.sh`). No new interruption test was added.

5. **Descendant processes on timeout: observed limitation, not fixed.**
   Coreutils `timeout` signals the child's process group, so same-group
   background descendants died. A background job that created its own process
   group (`set -m`) survived. Containing that needs a new mechanism and a
   stated trust boundary, so it is recorded as a decision for the owner.

## Implemented changes

- `scripts/loop.sh`: items 1–3 above. Expectations are decoded once at startup
  with the other fixed metadata, so judging no longer re-reads the kit file.
  Expectation shape is validated in one `jq` call, and NUL bytes in task fields
  are rejected before the NUL-delimited decoding (reasoned from the decoder; not
  reproduced separately). Judge order, full-line matching, coverage, acceptance
  repetition and Bash 3.2 compatibility are unchanged.
- `scripts/test_loop.sh`: 8 new cases (38 total), each with a deliberate
  regression: custom and `./` task names, check-only mutation in both modes,
  TERM-ignoring judge and coder, and NUL rejection. Regressed copies run under
  an outer deadline with kill-after; the TERM-ignoring judge and coder cases
  also remove processes that a regressed copy leaves behind.
- `SKILL.md`: check-only mutation rule, kill-after timeout, case count and the
  list of runner differences from spec-loop.

## Performance (orchestration only)

Command: `python3 tests/benchmark_loop.py [runner]`, 40 passing no-op tasks,
three serial runs per mode, temporary repository, two invocations per runner.
Bash 3.2 throughout; no model calls or downloads.

| Runner | `--check-once` median | `--check` median |
| --- | ---: | ---: |
| `a1f9daa` (before), invocation 1 | 0.645 s | 6.591 s |
| working tree (after), invocation 1 | 0.430 s | 4.643 s |
| `a1f9daa` (before), invocation 2 | 0.633 s | 6.942 s |
| working tree (after), invocation 2 | 0.453 s | 4.969 s |

Process launches on the same 40-task fixture (a `PATH` shim counted calls):
`--check-once` 133 to 15 `jq` launches; `--check` 913 to 15 `jq`; `git`
1 to 5 (two tree snapshots at two `git` calls each). The snapshot cost grows
with repository size and was not measured on a large repository.

These are no-op orchestration times only. Application test time, live coding
time and lifecycle cost were not measured.

## Lightweight lifecycle record (existing evidence)

Operator active minutes were not recorded for either run, so they are marked
unavailable, not zero. Cost is the report's stated figure.

| Phase | Run | Source revision | Start to end (UTC) | Elapsed | Cost | Attempts / retries | Outcome | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Implementation | run1 | `f8f224f` | 07:52:40 to 08:17:51 | 25 m 11 s | $2.18 (reported) | 12 / 0 | 20/20 pass | `drift-loop-eval/run1-report.md` |
| Corrective | run2 | `b242c9c` | 08:40:55 to 08:44:41 | 3 m 46 s | $0.23 (reported) | 6 / 0 | 26/26 pass | `drift-loop-eval/run2-corrective/report.md` |
| Discovery, specification, judge, reference, qualification, review | — | — | unavailable | unavailable | unavailable | — | — | not recorded in the reports |
| Operator active minutes | — | — | unavailable | unavailable | unavailable | — | — | not recorded |

## Comparative pilot: prepared, not launched

No live pilot was run or authorized. This controller does not authorize nested
paid calls, so no model or CLI command was run for the pilot. Blocked inputs:

- owner-selected representative assignment, with the README and starting tree frozen;
- withheld behavioral checks authored independently, with evaluation access separated from implementation tools;
- pinned framework and model revisions, provider pricing, total budget and retry or stop policy;
- owner-approved model commands and commit/discard permissions; SIE source and ownership if SIE is included.

## Validation (observed)

Before any edit, the baseline suites passed: `scripts/test_loop.sh` 30/30 cases
and 30/30 regressions; `tests/run.sh` 13/13 toy assertions; the three Python
test files OK.

After the changes:

- `bash -n` on `scripts/loop.sh`, `scripts/test_loop.sh`, `scripts/install.sh`, `tests/run.sh` and `tests/fakecoder.sh`: passed.
- `bash scripts/test_loop.sh` (final run, 5 m 26 s): 38/38 cases passed, 38/38 regressions caught, exit 0, no leftover judge or coder processes.
- `bash tests/run.sh` with `GOPROXY=off`, `GOTOOLCHAIN=local`, and temporary `GOCACHE` and `GOMODCACHE`: 13 `ok`, exit 0.
- `python3 tests/test_install.py`, `tests/test_kit_format.py`, `tests/test_runner_config.py`: all OK.
- `git diff --check`: clean.
- Git config for every fixture: `GIT_CONFIG_GLOBAL=/dev/null`, `GIT_CONFIG_NOSYSTEM=1`.

Environment limits: only Bash 3.2.57 was available (no newer Bash was checked);
`/usr/bin/timeout` on this Mac supports `-k`; Linux CI was not run; the
installed skill was not touched.

Experiment evidence (baseline → fix):

| Check | Baseline | Fix |
| --- | --- | --- |
| `TASKS=tasks+v2.json`, cheat edits kit `expect` | exit 0, edited kit committed | exit 2 (STOP); HEAD `expect` unchanged |
| `TASKS=./tasks.json`, same cheat | exit 0, edited kit committed | exit 2 (STOP); HEAD `expect` unchanged |
| Default `tasks.json`, same cheat (control) | exit 2 | exit 2 |
| `--check` / `--check-once`, mutating check | exit 0 / exit 0 | exit 1 / exit 1 |
| TERM-ignoring judge, `JUDGE_TIMEOUT=1` | unbounded (killed by outer deadline at 12 s) | killed at 6 s, exit 1 |

## Review requests (for an independent reviewer)

- Try `TASKS` spellings: plus, `./`, absolute through a symlink, subdirectory, and a name with a newline.
- Confirm that the check-only snapshot leaves the real index unchanged and that ignored files stay out of the snapshot, as in attempt mode.
- Try a judge that ignores SIGTERM, one that spawns a same-group grandchild, and one that uses `setsid` or `set -m`.
- Run the suite under Bash 3.2 and a newer Bash.
- Check that a judge which writes a non-ignored file fails `--check` and `--check-once`.

## Deferred decisions and limitations

1. Should an interrupted attempt count toward `MAX_ATTEMPTS`? Current: yes.
2. Should timeouts contain descendants outside the process group? Current: no.
3. Should check-only modes restore a mutated tree, or only report it? Current: report only.
4. Should kit checks that stage files (for example `git add -A`) be rejected? Current: the index is not compared.
5. Per-expectation `grep` processes remain. Bash regex matching could remove them, but would change matching semantics, so it was not done.
6. Operator STOP semantics, attempt discard policy and model-tier escalation are unchanged. No silent stop policy was added.
7. `README.md`'s dated "Runner metadata performance" and "Installer validation" paragraphs still describe earlier validation counts. Left as history.

## Source state

- Base: `a1f9daa`. Branch: `overnight-reliability-performance`. Commit: see `git log`.
- Changed files (committed): `scripts/loop.sh`, `scripts/test_loop.sh`, `SKILL.md`, `references/development-review.md`.
- SHA-256 after changes: `scripts/loop.sh` `7b35fa732da925e27218198582713ba0195bb7854cbb87df0ad6ee86a393b28b`; `scripts/test_loop.sh` `6b9e54a7061fc6151b578acfe3e28eee743818efd14c75f06c575fb1fa99dd73`; `SKILL.md` `c349be1f70c3d9f7fa6bbb4eb70a79b67260831cea999539e7ab47fc7357dc4c`.
- Baseline `scripts/loop.sh` SHA-256 at `a1f9daa`: `232a5c0a35496f10e791ab164f0a12b9760e9260025017252d53f9bb6f7097a1`
- Untracked `ARTICLE-DRAFT.md` left untouched and not committed.
- Not merged to `main`; pending independent review.

## Unrelated activity noticed

While this work ran, a `scripts/loop.sh --check` run in `/Users/rob/Development/drift`
from another session was active (PID 35018). I did not inspect, stop or touch it,
or that repository.
