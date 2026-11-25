# Bounded development review

## Authority, scope and independent review

Branch `overnight-reliability-performance`, base `a1f9daa`. Local edits, tests
and commits only: no push, release, dependency install, installed-skill change,
production or SIE access, agent, model/API or CLI model call, and no nested job.
`ARTICLE-DRAFT.md` is untracked, was not read for this work and is not added.

**Independent review of this change: not performed.** No reviewer agent was
authorized for this session, so everything in this report from the second round
of work is self-review and not evidence of independent verification.

An earlier read-only review of commit `ed40ea0` was made by a separate reviewer
session (its result is in the private overnight artifacts). It made no changes and
approved nothing. Its findings were checked against source; the disposition of each
is in the table below. Do not merge to `main` until an independent reviewer has
checked the diff in `scripts/loop.sh`, `scripts/test_loop.sh` and the `SKILL.md`
contract edits, with the attacks listed under "Review requests".

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

## Preceding review: verification and disposition

Each finding was checked against source. Reproductions ran on the unedited
runner (`a1f9daa`/`ed40ea0`) in disposable fixtures under `/var/folders` temp
directories, then on the final runner.

| # | Finding (preceding review) | Verified | Disposition |
| --- | --- | --- | --- |
| 1 | `.loop/` ignore rule not protected; coder can remove it | Yes. Removing the rule made the discard path's `git clean -fd` **delete `.loop/`** (loop log and attempt counters lost). The commit was avoided only because the judge's log writes then counted as a tree change. | Fixed: `revert_protected` restores `.gitignore` from HEAD when `.loop/` is no longer ignored. Protecting `.gitignore` by default was the alternative; not chosen, so the coder can still add ignore rules. **Owner to confirm.** |
| 2 | Protected write between restoration and snapshot is judged and committed | Yes by construction; the window is between `revert_protected` and `git write-tree`. Needs a surviving descendant to hit in practice (deferred item 2). | Fixed: `protected_in_tree` refuses the attempt if the judged tree changes a protected path relative to HEAD. Regression injects the write into a copy of the runner. |
| 3 | Git quotes non-ASCII paths, so protected matching misses them | Yes. A cheat to `dé/README.md` was committed under the default protection. | Fixed: NUL-delimited `git diff -z`/`ls-files -z` input. |
| 3a | (found during verification) A rename hides the old path | Yes. A renamed `PROMPT.md` was missing from the commit (the old path was not restored). | Fixed: `--no-renames`. |
| 4 | Coder timeout does not fail the attempt, contrary to SKILL.md | Yes. A coder timed out after writing a passing change was committed. | Fixed: a coder timeout (124 or 137) fails the attempt, as the contract says. |
| 5 | Empty numeric overrides silently default; blank owner commands pass | Yes. `MAX_ITER=` ran with 60; `CHEAP_CMD=' '` was accepted. | Fixed: empty values are refused; blank commands are refused. |
| 6 | Expectation containing a newline is an OR of lines | Yes. Test printed `FAIL T1` and exited 0; expectation `PASS T1\nFAIL T1` passed. | Fixed: refused at startup (single-line expectations). |
| 7 | Timeout-label assertion may depend on `timeout` implementation | Not verified here: only macOS `timeout` is installed. | Test now accepts either `killed` or `timed out`. GNU `timeout` behaviour is **unverified**. |
| 8 | Failed `git add` inside snapshot is silent | Yes. With an unreadable file, `--check-once` printed `fatal: adding files failed`, then `pass T1`, and exited 0. | Fixed: snapshot failures return non-zero and fail the check. |
| 9 | Judge creating an untracked file fails check-only modes (undocumented) | Confirmed by a new regression. | Documented in SKILL.md and covered by `check-untracked`. |
| 10 | `.loop/` state writable by coder; attempt budget can be reset | Yes (by design of the state directory). | Not changed. Deferred decision 8. |
| 11 | README stale counts and unattributed timings | Yes. README said 30 cases and quoted timings tied to no revision. | Counts updated to 48; timings removed and replaced with a pointer here. |
| 12 | README says Stage 5a was measured, and also that the time saving is an estimate | Yes, the two statements conflict. The Stage 5a source could not be checked. | Not changed (approved decision text). Deferred decision 11. |
| 13 | "One jq call" comments were inaccurate | Yes. Startup uses several fixed jq calls. | Comments corrected. |
| 14 | Performance evidence is thin | Partly. Only no-op orchestration measured; snapshot cost on a large repository not measured. | Benchmark re-run on final code (below); gap stated. |
| 15 | Baseline runs predate the judge changes | Yes. | Noted; baseline figures are not evidence for this diff. |

Test gaps the preceding review listed, now covered by regressions:
non-ASCII protected path, rename masking, `.gitignore` removal, coder timeout,
multi-line expectation, blank and empty overrides, snapshot failure, judge-created
untracked file, protected write before snapshot.

Test gaps still open: `expect` that is not an array or holds non-string or empty
items (startup check exists; no dedicated regression); NUL bytes in `id`, `test`
or `expect` (existing check; no dedicated regression); invalid `protected` regex
pattern case; interrupted-attempt accounting (deferred); `pkill -f` cleanup in the
suite matches by global command-line pattern (`rl-test-hang`, `fake.sh cheap`),
which is low risk but unscoped.

## Runner investigation (round one, unchanged)

Each item was reproduced first in disposable fixtures with the unmodified runner
(`a1f9daa`), then rechecked against the fix.

1. **Custom `TASKS` path protection: defect, fixed.** The task file name was
   interpolated into the protection ERE (`tasks+v2.json` was not protected;
   `./tasks.json` never matched). The fix protects the task file by exact,
   repository-relative name, with no regex.
2. **Check-only mutation: defect, fixed.** `--check` and `--check-once` compare
   working-tree snapshots taken through a temporary index in `.loop/`, so the
   user's staged state is untouched. A change exits 1 and logs
   `judge commands modified the tree`.
3. **Judge and coder timeouts: defect, fixed.** Judge and coder commands get
   `timeout -k 5`. The fixed grace period is not an owner setting.
4. **Restart and attempt accounting: observed, not changed.** An interrupted
   attempt consumes budget and escalates. Deferred decision 1.
5. **Descendant processes on timeout: observed limitation, not fixed.** Coreutils
   `timeout` signals the child's process group; a descendant that sets its own
   process group survives. Deferred decision 2.

## Implemented changes (this session)

- `scripts/loop.sh`: findings 1–6 and 8 above; `protected_in_tree` after the
  judged snapshot; comment corrections. The judge order, full-line matching,
  coverage, acceptance repetition, `--check-once` single pass and Bash 3.2
  constructs are unchanged.
- `scripts/test_loop.sh`: 10 new cases (48 total), each with a deliberate
  regression run against a disposable copy: `empty-override`, `blank-command`,
  `newline-expect`, `rename-protected`, `quoted-protected`, `gitignore-edit`,
  `coder-timeout`, `protected-window`, `check-untracked`, `unreadable-snapshot`.
  The TERM-ignoring judge assertion accepts either timeout label.
- `SKILL.md`: protected matching, `.gitignore` restoration, single-line
  expectations, untracked-file and snapshot-failure rules for check-only modes,
  override and blank-command rules, coder-timeout rule, 48 cases, runner
  differences.
- `README.md`: stale counts and unattributed timings replaced with a pointer to
  this report. The approved decision table was not edited.
- `references/development-review.md`: this report.

## Performance (orchestration only)

Command: `python3 tests/benchmark_loop.py [runner]`, 40 passing no-op tasks, three
serial runs per mode, two invocations per runner, temporary repository, Bash 3.2.57,
no model calls or downloads. Baseline runner: `a1f9daa` `scripts/loop.sh`
extracted from git to a temporary directory (SHA-256 prefix `232a5c0a35496f10`).

| Runner | `--check-once` median (2 invocations) | `--check` median (2 invocations) |
| --- | ---: | ---: |
| `a1f9daa` (before) | 0.751 s, 0.718 s | 7.190 s, 7.118 s |
| final working tree (after) | 0.473 s, 0.450 s | 5.032 s, 4.991 s |

Earlier measurements in the previous session (`a1f9daa` 0.645 s/6.6–6.9 s; the
earlier working tree 0.43–0.45 s/4.6–5.0 s) are consistent with these ratios but
came from a different machine state; they are not repeated as current evidence.

The new per-attempt checks (`protected_in_tree`, one extra `check-ignore`) are on
the attempt path, which this benchmark does not measure. Snapshot cost grows with
repository size and was not measured on a large repository. Application test time,
live coding time and lifecycle cost were not measured.

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
paid calls, so no model or CLI command was run for the pilot. The runner changes
above have not been exercised on a live kit; the pilot should start only after
independent review. Blocked inputs:

- owner-selected representative assignment, with the README and starting tree frozen;
- withheld behavioral checks authored independently, with evaluation access separated from implementation tools;
- pinned framework and model revisions, provider pricing, total budget and retry or stop policy;
- owner-approved model commands and commit/discard permissions; SIE source and ownership if SIE is included.

## Validation (observed in this session)

Before any edit, the baseline suite was re-run: `scripts/test_loop.sh` **38/38
cases and 38/38 regressions, exit 0**, observed by me.

After the changes (final code, Bash 3.2.57, `/bin/bash`):

- `scripts/test_loop.sh`: **48/48 cases passed, 48/48 regressions caught, exit 0**,
  no model calls. The suite runs every case against the fixed runner and every
  mutant against its regressed copy. `protected-window` and `unreadable-snapshot`
  were also run on their own during development, before the final full run.
- `tests/run.sh` with `GOPROXY=off`, `GOTOOLCHAIN=local` and temporary `GOCACHE`
  and `GOMODCACHE`: 13 `ok`, exit 0.
- `python3 tests/test_install.py`, `tests/test_kit_format.py`,
  `tests/test_runner_config.py`: all OK.
- `bash -n` on `scripts/loop.sh`, `scripts/test_loop.sh`, `scripts/install.sh`,
  `tests/run.sh`, `tests/fakecoder.sh`: passed.
- `git diff --check`: clean.
- Benchmark: as above.
- Reproductions against the final runner (disposable fixtures): renamed protected
  file restored; non-ASCII protected file restored; ignore rule restored with no
  `.loop/` committed and loop state kept; timed-out coder not committed (exit 3,
  cap); `MAX_ITER=` refused; blank `CHEAP_CMD` refused; newline expectation refused;
  unreadable file makes `--check-once` exit 1.

Environment limits: only Bash 3.2.57 is installed (no newer Bash was checked);
`/usr/bin/timeout` on this Mac supports `-k`; GNU `timeout` was not checked; Linux
CI was not run; the installed skill was not touched. The `unreadable-snapshot`
case needs a non-root user (root reads `chmod 000` files).

## Review requests (for an independent reviewer)

- Try `TASKS` spellings: plus, `./`, absolute through a symlink, subdirectory, a name with a newline.
- Try protected paths with non-ASCII names, renames (`git mv`) of protected files, and a protected file deleted by the coder.
- Try a coder that removes the `.loop/` rule, adds other ignore rules, or creates `.loop/` contents of its own.
- Try a coder that exits after a timeout having written a passing change; confirm no commit.
- Confirm that `protected_in_tree` refuses a write injected between restoration and snapshot, using a copy of the runner (the `protected-window` case).
- Confirm that the check-only snapshot leaves the real index unchanged and that ignored files stay out of the snapshot, as in attempt mode.
- Try a judge that ignores SIGTERM, one that spawns a same-group grandchild, and one that uses `setsid` or `set -m`.
- Run the suite under a newer Bash and, if possible, GNU `timeout` (check the exit status for a timeout that needed KILL).

## Deferred decisions and limitations

1. Should an interrupted attempt count toward `MAX_ATTEMPTS`? Current: yes.
2. Should timeouts contain descendants outside the process group? Current: no.
3. Should check-only modes restore a mutated tree, or only report it? Current: report only.
4. Should kit checks that stage files (for example `git add -A`) be rejected? Current: the index is not compared.
5. Per-expectation `grep` processes remain. Bash regex matching could remove them, but would change matching semantics, so it was not done.
6. Operator STOP semantics, attempt discard policy and model-tier escalation are unchanged. No silent stop policy was added.
7. `README.md`'s dated "Installer validation" paragraph still describes earlier validation counts. Left as history.
8. **New.** The `.loop/` state directory is inside the worktree and writable by the coder. The attempt counter, notes (fed back into later prompts) and logs can be edited, which resets the budget or escalation. Moving state outside the worktree or making it read-only for the coder is a contract choice for the owner.
9. **New.** `.gitignore` is restored when the `.loop/` rule breaks, not protected by default. Confirm this or switch to protection.
10. **New.** A coder timeout now fails the attempt and its partial work is discarded, as SKILL.md always said. Confirm this is the intended behaviour for long coder runs.
11. **New.** README's approved decision row (Stage 5a judging "about 2 of roughly 3 hours") conflicts with the note that the saving is "an estimate, not yet measured on a stage". The Stage 5a source was not checked. Owner to confirm which statement stays.
12. **New.** GNU `timeout` exit status for a command that needed KILL is unverified. The test accepts either label.
13. **New.** Snapshot cost on a large repository is unmeasured; the per-attempt checks are not in the benchmark.

## Source state

- Base: `a1f9daa`. Branch: `overnight-reliability-performance`. Prior commit `ed40ea0`. The commit for this round is recorded in `git log`.
- Changed files: `scripts/loop.sh`, `scripts/test_loop.sh`, `SKILL.md`, `README.md`, `references/development-review.md`.
- SHA-256 after changes: `scripts/loop.sh` `a24c5348bd21f317f007fc2a3a91a09811b9f78345223aa9151af9c3f010d2ee`; `scripts/test_loop.sh` `bbe9e3df0c8abd0cf6157344160e731ee1f3a7ad4ee4c95d3775d2db15e2117b`.
- Baseline `scripts/loop.sh` SHA-256 at `a1f9daa`: `232a5c0a35496f10e791ab164f0a12b9760e9260025017252d53f9bb6f7097a1`.
- Untracked `ARTICLE-DRAFT.md` left untouched and not committed.
- Not merged to `main`; pending independent review. No remote operation.

## Unrelated activity noticed

During the first round of work, a `scripts/loop.sh --check` run in
`/Users/rob/Development/drift` from another session was active (PID 35018). I did
not inspect, stop or touch it, or that repository. Not observed in this round.
