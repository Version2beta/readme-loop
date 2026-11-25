# Bounded development review

## Authority, scope and independent review

Branch `overnight-reliability-performance`. The first two rounds below used base
`a1f9daa`. The continuation section starts from `816f36f`, the base of the final
review. Local edits, tests and commits only: no push, release, dependency install,
installed-skill change, production or SIE access, agent, model/API or CLI model
call, and no nested job. This session may not start model calls, so all paid work
must go through the owner's controller. `ARTICLE-DRAFT.md` is untracked, was not
read for this work and is not added.

**Independent review of this change: not performed.** No reviewer agent was run.
A reviewer is a model call, which this session may not start, so the reviewer
authorization in the continuation brief cannot be used here. Everything in this
report from the rounds of work is self-review and not evidence of independent
verification. A fresh reviewer would also be of the same model family as the
writer, which limits its independence.

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

## Continuation from `816f36f`: medium and low findings

Source of the findings: the final review at `816f36f` (its result fields were
read from the private overnight artifact). Each defect was first reproduced with
the unchanged runner (`816f36f`) in disposable fixtures under `/tmp/rl-exp`, using
a fake coder: no model, no network, no real repository. Each fix was then rechecked
on the fixed runner. Each new regression case was also run against the old runner
and fails there on the stated assertion.

| Finding | Reproduced on `816f36f` | Disposition |
| --- | --- | --- |
| **M1** Index flags (`assume-unchanged`, `skip-worktree`) hide a protected file | **Yes.** The coder set the flag on `verify.sh`, wrote `echo PASS T1` into it and also wrote `feature.txt`. Loop exit 0, "every task passes". HEAD kept `FAIL`; the judge ran `PASS`; `git status` was clean. Without the extra file, the commit failed with exit 1 and left the cheat hidden from status. | **Fixed.** Startup refuses flags the user set. After each coder run, flags are cleared before restoration or snapshot: `git update-index` takes one mark option per call (a combined call clears only the last one; checked), so each flag is cleared in its own call. Cases `index-flags`, `index-flags-skip`, `index-flag-startup`. |
| **M2a** An ignore rule hides a source file, so the judge sees a file the commit lacks | **Yes.** The coder added `src.txt` to `.gitignore` and wrote `src.txt`. The judge passed; HEAD lacks `src.txt`; exit 0. | **Not fixed; policy.** Judging on ignored files that the commit lacks has no safe general rule: the same mechanism covers legitimate caches and generated outputs. Pass now logs a warning that names the ignored files the attempt created. Case `ignored-pass-warning`. Open decision 14. |
| **M2b** Discarded ignored artifacts satisfy a later judge | **Yes.** Attempt 1 wrote `ignored/artifact` and failed; `git clean -fd` left it. Attempt 2 passed. The archive of HEAD failed the same test. | **Fixed.** A discard removes ignored files the attempt created: a set difference against a listing taken before the coder. Ignored files that existed before the attempt, and `.loop/`, are kept. Case `ignored-discard`. |
| **L1** Git failures are hidden in restoration | Not reproduced; needs a git failure in the middle of a command. | **Fixed by reading.** Listings go to a file. A failing listing stops the run in restoration, and `protected_in_tree` refuses the attempt, so the run does not pass on an unlisted change. No regression case. |
| **L2** Restore pathspec matches globs | **Yes.** A protected `a*b` restored the unprotected `aXb` and reverted the coder's change. | **Fixed:** `:(literal)` pathspec. Case `glob-pathspec`. |
| **L3** Coder-writable attempt count is evaluated as arithmetic | **Yes.** `state[$(touch .loop/pwned)]` in `.loop/attempts.T1` created the file on `816f36f`. | **Fixed:** the count must be digits, read with `10#`. Case `attempts-corrupt`. |
| **L4** Late write after the index snapshot | Not reproduced. Reading: the commit contains only the judged tree, and the dirty worktree stops the run with exit 1. | **Left as is.** The run stops loudly, and the next clean-start gate refuses the dirty tree. |
| **L5** Blank kit commands | **Yes.** `check` set to blanks passed with exit 0. | **Fixed:** a blank `format`, `format_check` or `check` is a kit error. Case `blank-kit-command`. |
| **D1** Stale counts | Yes: README and SKILL.md said 47. | **Fixed:** 56 cases (48 plus the 8 new cases). |
| **D2** Stage 5a time-saving statements conflict | Not checked. | **Not changed.** Owner decision 11. |
| **D3** Hashes not verified | Verified against git blobs, not against trust. `816f36f` `scripts/loop.sh` is `a24c5348…`; `a1f9daa` is `232a5c0a…`; `816f36f` `scripts/test_loop.sh` is `bbe9e3df…`; the README packaging hash `4ed33daa…` is a blob in `scripts/loop.sh` history. | Recorded below; the README packaging hash remains labelled history. |

New regression cases: `index-flags`, `index-flags-skip`, `index-flag-startup`,
`ignored-discard`, `ignored-pass-warning`, `attempts-corrupt`,
`blank-kit-command`, `glob-pathspec`. Each has a deliberate regression in the
suite (a mutant of the fixed line). Each mutant is caught.

### Behaviour changes a reader should know about

- Startup refuses index flags set by the user (`assume-unchanged` or
  `skip-worktree`). Previously they hid edits from the clean-start gate.
- A discarded attempt removes the ignored files it created, including caches the
  coder built during that attempt. The next attempt must recreate them. Caches that
  existed before the attempt are kept.
- A blank kit `format`, `format_check` or `check` is refused. A blank command
  used to be skipped or to pass as a no-op.
- A corrupt attempt counter stops the run with a message instead of being guessed.

### What remains open (not fixed, stated plainly)

- A passing attempt can leave ignored files that the commit does not contain.
  They stay in the worktree and can affect later judging (M2a, decision 14).
- A discarded attempt does not restore pre-existing ignored files that it
  modified in place (decision 15). Only files it created are removed.
- The ignored-file listing runs twice per attempt. Its cost grows with the number of
  ignored files; see Performance.
- Ignored file names containing a newline are not handled. The startup check for
  untracked files has the same limit.

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

### Continuation measurements (attempt path and check modes)

Measured with `/tmp/rl-exp/perf/measure.py` (disposable repositories under `/tmp`,
not committed). Each attempt is one fake coder that writes `ok`, a task that passes,
and the runner's commit. Each check is `--check` on a repository whose task passes.
Median of three runs; a fresh copy per run; `maintenance.auto` is off in the
templates, because a background repack in a commit moved objects during copying.
The machine was shared with an unrelated process (load average about 3), so the
numbers are indicative, not precise.

| Tracked files | Ignored files | Mode | `816f36f` | Working tree | Difference |
| ---: | ---: | --- | ---: | ---: | ---: |
| 0 | 0 | attempt | 0.207 s | 0.238 s | +0.031 s |
| 2,000 | 0 | attempt | 0.266 s | 0.311 s | +0.045 s |
| 20,000 | 0 | attempt | 0.696 s | 0.759 s | +0.063 s |
| 20,000 | 20,000 | attempt | 0.737 s | 0.819 s | +0.082 s |
| 0 | 0 | check | 0.084 s | 0.084 s | 0 |
| 2,000 | 0 | check | 0.181 s | 0.182 s | +0.001 s |
| 20,000 | 0 | check | 1.759 s | 1.746 s | −0.013 s |
| 20,000 | 20,000 | check | 1.795 s | 1.789 s | −0.006 s |

The repository benchmark (`tests/benchmark_loop.py`, 40 no-op tasks) gave
`--check-once` medians of 0.426 s (`816f36f`) and 0.468 s (working tree), and
`--check` medians of 4.884 s and 4.810 s. The `--check-once` difference is within
this machine's run-to-run spread, and check-only modes do not execute the new code.

What this shows:

- A no-op attempt gains about 30–80 ms. The new work is one index-flag listing,
  two ignored-file listings and one set difference. It grows with the number of
  tracked and ignored files; the largest measured case is 40,000 files in total.
- Check-only modes are unchanged in these measurements.
- Not measured: coder time, application test time, model latency, and ignored trees
  larger than 20,000 files. Those dominate real attempts; the added cost is small
  beside them, but that is an inference from these measurements, not a measurement
  of a real attempt.

## Lightweight lifecycle record (existing evidence)

Operator active minutes were not recorded for either run, so they are marked
unavailable, not zero. Cost is the report's stated figure.

| Phase | Run | Source revision | Start to end (UTC) | Elapsed | Cost | Attempts / retries | Outcome | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Implementation | run1 | `f8f224f` | 07:52:40 to 08:17:51 | 25 m 11 s | $2.18 (reported) | 12 / 0 | 20/20 pass | `drift-loop-eval/run1-report.md` |
| Corrective | run2 | `b242c9c` | 08:40:55 to 08:44:41 | 3 m 46 s | $0.23 (reported) | 6 / 0 | 26/26 pass | `drift-loop-eval/run2-corrective/report.md` |
| Discovery, specification, judge, reference, qualification, review | — | — | unavailable | unavailable | unavailable | — | — | not recorded in the reports |
| Operator active minutes | — | — | unavailable | unavailable | unavailable | — | — | not recorded |

## Comparative pilot: not run, and the earlier "not authorized" claim is withdrawn

The earlier text said no live pilot was "run or authorized", and listed owner
assignment, model commands, a total budget and commit/discard permissions as
blocked. **That was wrong about authority.** The continuation brief authorizes:

- choosing a small, disposable, non-destructive CLI pilot;
- live experiments and paid work, through the controller only;
- the models Haiku 5.5 (the controller uses exactly `claude-haiku-5-5`) and `gpt-6.1-sol`;
- a spending limit of $8 for the controller;
- isolated automatic commits and discards, and local Git handoffs.

Authority is therefore not the blocker. What is not done, and why, is separate:

- **Execution boundary, not authority.** This session may not start model calls.
  The pilot must be run by the controller. No pilot command was run here, and no
  pilot assignment was chosen or prepared in this session. The requested package
  did not include the pilot.
- **Methodological limits (these would apply even with full authority):**
  - No behavioral checks have been written independently for a pilot assignment.
    They must be authored apart from the implementation agent.
  - The runner changes have not run on a live kit. The fake coder does not exercise
    the real `pi` integration, so it cannot show how a live coder behaves.
  - One assignment with one run per arm cannot estimate variance. Any comparison needs
    repeated runs.
  - The provider price of `gpt-6.1-sol` and the pilot's total cost were not verified
    in this session.
  - Independent review of the pilot design has not been run (see the authority
    section). A reviewer of the same model family limits independence.
- **Owner decisions still open** (they change the contract, not the pilot's authority):
  decisions 8, 9, 10, 11 and 14 below.

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

## Continuation validation (observed in this session)

- Baseline before any edit: `scripts/test_loop.sh` at `816f36f`, **48/48 cases and
  48/48 regressions, exit 0**, about 8 minutes.
- Final, on the working tree (the commit records the same files): `scripts/test_loop.sh`
  **56/56 cases and 56/56 regressions, exit 0**. This run came after the last test edit.
- The eight new cases fail on `816f36f` for their stated reason: `index-flags` and
  `index-flags-skip` (the attempt is committed with rc 0 while the judge had run on the
  cheat), `index-flag-startup`,
  `ignored-discard`, `ignored-pass-warning`, `attempts-corrupt` (payload runs),
  `blank-kit-command` (rc 0), `glob-pathspec` (`aXb` reverted).
- Reproductions on `816f36f` and again on the fixed runner (disposable fixtures under
  `/tmp/rl-exp`, fake coder): M1 assume-unchanged and skip-worktree; M2a; M2b; L2; L3;
  L5. Results are in the continuation table.
- `tests/run.sh` (Go toy kit) with `GOPROXY=off`, `GOTOOLCHAIN=local` and temporary
  `GOCACHE`/`GOMODCACHE`: 13 `ok`, exit 0.
- `python3 -I tests/test_install.py`, `tests/test_kit_format.py`,
  `tests/test_runner_config.py`: all OK.
- `bash -n` on `scripts/loop.sh`, `scripts/test_loop.sh`, `scripts/install.sh`,
  `tests/run.sh`, `tests/fakecoder.sh`: passed. `git diff --check`: clean.
- Performance: the repository benchmark and the attempt-path measurements above.

Environment limits: Bash 3.2.57 (`/bin/bash`, arm64 macOS) only; `timeout` from
macOS; no Linux; GNU `timeout` not checked; not run as root (the `unreadable-snapshot`
case is valid for this user); no live coder, no live kit, no model calls. The
`unreadable-snapshot` and `timeout` cases were not re-checked on another platform.

## Review requests (for an independent reviewer)

- Try `TASKS` spellings: plus, `./`, absolute through a symlink, subdirectory, a name with a newline.
- Index flags: set `assume-unchanged` or `skip-worktree` on an unprotected file and
  edit it. The flag is cleared and the edit is committed. Confirm that is intended.
- Ignored files: a coder that edits a pre-existing ignored file in a failed attempt.
  Expected gap: the edit stays (decision 15). A coder that creates files in a
  pre-existing ignored directory: only the new paths should be removed.
- Attempt counter values such as `08` and `0009`: `10#` should read them as decimal.
- Names with spaces or non-ASCII characters in index flags and ignored files.
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
13. **New.** Snapshot cost on a large repository is unmeasured; the per-attempt checks are not in the benchmark. (Measured in the continuation; see Performance.)
14. **New (M2a, open policy).** May a passing attempt be judged on ignored files that its commit does not contain? Current: yes, with a warning in `.loop/loop.log`. The options are: (a) refuse a pass that creates ignored files, which would block coders whose own test runs create caches such as `__pycache__`; (b) allow a list of cache paths named by the owner and refuse other ignored files; (c) judge in a clean export of the committed tree, which changes what the judge sees and costs time. Related: decision 9 (`.gitignore` is not protected by default).
15. **New.** A discarded attempt removes ignored files it created, but does not restore pre-existing ignored files it modified in place. Options: keep a content copy of ignored files (cost grows with their size) or accept the gap.
## Source state

- Continuation base: `816f36f`. Branch: `overnight-reliability-performance`. The continuation commit is recorded in `git log`; `main` was not touched.
- Earlier rounds: base `a1f9daa`, prior commit `ed40ea0`.
- Changed files in the continuation: `scripts/loop.sh`, `scripts/test_loop.sh`, `SKILL.md`, `README.md`, `references/development-review.md`.
- Continuation SHA-256 (working tree at the time of the final suite run): `scripts/loop.sh` `faefa253dff9fe6e728075f01a0f8a6a50a147066f9da3db7af85b72a9f582dd`; `scripts/test_loop.sh` `0a4aaf2300c92586d8cab20a1c12bf52b526316ddec0ea785a6915b61b54603c`.
- Earlier-round hashes: `scripts/loop.sh` at `816f36f` `a24c5348…`, at `a1f9daa` `232a5c0a…`; `scripts/test_loop.sh` at `816f36f` `bbe9e3df…`. All verified against blobs in git history.
- SHA-256 after changes: `scripts/loop.sh` `a24c5348bd21f317f007fc2a3a91a09811b9f78345223aa9151af9c3f010d2ee`; `scripts/test_loop.sh` `bbe9e3df0c8abd0cf6157344160e731ee1f3a7ad4ee4c95d3775d2db15e2117b`.
- Baseline `scripts/loop.sh` SHA-256 at `a1f9daa`: `232a5c0a35496f10e791ab164f0a12b9760e9260025017252d53f9bb6f7097a1`.
- Untracked `ARTICLE-DRAFT.md` left untouched and not committed.
- Not merged to `main`; pending independent review. No remote operation.

## Unrelated activity noticed

During the first round of work, a `scripts/loop.sh --check` run in
`/Users/rob/Development/drift` from another session was active (PID 35018). I did
not inspect, stop or touch it, or that repository. Not observed in this round.
