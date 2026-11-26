# Historical v0.1 development review

This record preserves the earlier maintenance campaign, its findings and evidence.
It is not the v0.2 workflow contract, a current validation report, or evidence of
end-to-end economic superiority. See [README.md](../README.md) for current scope.
The underlying dispositions and measurements below are retained as history.

## Authority, scope and independent review

Branch `overnight-reliability-performance`. The first two rounds below used base
`a1f9daa`. The first continuation starts from `816f36f`, the base of the final
review. The second continuation starts from `7496c6f` (the first continuation's commit).
The third and fourth continuations start from `3473942` and `623e758` (each the previous
continuation's head). Local edits, tests and commits only: no push, release, dependency install,
installed-skill change, production or SIE access, agent, model/API or CLI model
call, and no nested job. This session may not start model calls, so all paid work
must go through the owner's controller. `ARTICLE-DRAFT.md` is untracked, was not
read for this work and is not added.

**Independent review of the second continuation: not performed.** No reviewer agent
was run, and this session may not start one: a reviewer is a model call. The
changes in the second continuation (below) have had only self-review and local
tests. The findings they answer came from a read-only review of `7496c6f` by a
reviewer of the same model family as the writer. That review is an input to this
work, not a review of these changes. Everything else in the rounds of work is
self-review and is not evidence of independent verification.

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
- Ignored file names containing a newline: resolved in the second continuation (below).
  The startup check for untracked files still lists names by line; a newline there
  makes the name appear differently, and the check refuses, so it is not a bypass.

## Second continuation from `7496c6f`: review findings

Source: a read-only review of `7496c6f` (from the private overnight result
`continuation/runner-review-3.json`; its verdict and finding text were read, and no
other result fields). The reviewer ran no commands and made no edits, and it is of
the same model family as the writer. Its findings were treated as hypotheses. Each
was reproduced first on the HEAD runner (`7496c6f` `scripts/loop.sh`, SHA-256
`faefa253…`) in disposable fixtures under `/tmp/rl-exp3`, with a scripted fake coder
and no model. Each regression case added here was also run on the HEAD runner, and
fails there for the stated reason.

| # | Finding | Reproduced on `7496c6f` | Disposition |
| --- | --- | --- | --- |
| 1 (high) | Both index flags set. `ls-files -v` prints a lowercase `s`, which `^[hS] ` did not match, so startup and the clearing step both missed it. | **Yes.** Attempt: rc 0 and `every task passes`, while HEAD's `verify.sh` still fails. Startup with both flags: rc 0, where refusal was expected. | **Fixed:** pattern `^[hsS] `. Cases `index-flags-both`, `index-flag-both-startup`. |
| 2 (high if reproduced) | A formatter or judge command sets an index flag, so the `git add -A` after the judge skips its edit. | **Yes.** rc 0 and `every task passes`, while HEAD fails. The flag stayed set on `verify.sh` after the run. The discard did not restore the flagged file, so the next iteration's test passed on the edit. | **Fixed:** a flag set after the coder fails the attempt. Flags are cleared before the snapshot, and the discard restores the file. Case `judge-flag`. Check-only modes are not affected: their temporary index ignores the real index flags. `--check` and `--check-once` both reported `judge commands modified the tree` (rc 1) on a judge that set a flag and edited the file. Those modes still leave the flag set (report-only, deferred decision 3). |
| 3 (medium) | An ignored file matching a protected pattern is judged, but it is not in the commit. | **Yes.** rc 0. `testdata/x` was absent from HEAD, and the warning was logged. | **Fixed:** ignored files the attempt created that match a protected pattern are removed before judging. Pre-existing ignored files are not touched. Case `ignored-protected`. |
| 4 (medium) | Git quotes non-ASCII and special ignored names, so the discard cannot remove them by the quoted text. | **Yes.** `"ignored/d\303\251/artifact"` was logged as removed but survived, and attempt 2 passed (rc 0). A name containing a newline also survived (rc 0). | **Fixed:** the listing is NUL-delimited and the set difference is NUL-safe. Cases `quoted-discard`, `newline-discard`. Newline names are now handled, so that limit in the first continuation no longer holds. |
| 5 (low) | A note line that begins with `++` is dropped. | **Yes.** `.loop/notes.T1` was empty. | **Fixed:** notes come from hunk bodies only. Case `plusplus-note`. |
| 6 (low) | A snapshot failure in attempt mode (`git add` on an unreadable file) exits with the attempt's changes left in the worktree. | **Yes, observed.** rc 128, with `M code` and `?? unreadable` left in the worktree and HEAD unchanged. The next clean-start gate refuses the dirty tree. | **Not changed. Deferred decision 16.** No commit is made and the run fails loudly. Discarding on a git failure would change the attempt-discard policy (decision 6). |

Documentation from the same review: the index-flag rules in `SKILL.md` now match
the runner for both flags and for judge-time flags; the stale "SHA-256 after
changes" line in "Source state" repeated the base hashes and is removed; decision 15
now covers deletions as well as modifications.

### Performance (second continuation)

Fake coder, one passing attempt (`MAX_ITER=1`), disposable repositories under
`/tmp/rl-exp3`, three runs each, one machine (its load was not controlled). The
harness is `/tmp/rl-exp3/perf.sh`, not committed. Check mode runs the judge only,
with no coder, so its test fails and it measures the judge path.

| Mode | Ignored files | `7496c6f` (s) | Working tree (s) |
| --- | ---: | --- | --- |
| attempt | 0 | 0.318, 0.310, 0.300 | 0.349, 0.349, 0.353 |
| attempt | 20,000 | 0.378, 0.340, 0.337 | 0.484, 0.502, 0.538 |
| check | 0 | 0.136, 0.119, 0.119 | 0.118, 0.122, 0.121 |
| check | 20,000 | 0.125, 0.138, 0.125 | 0.119, 0.123, 0.126 |

A passing no-op attempt costs about 0.03 s more with no ignored files, and about
0.15 s more with 20,000 ignored files. The added work is a few extra
`git ls-files` listings of ignored files per attempt, and one index-flag listing
after the judge. Check modes are unchanged within this run's spread. A first
version compared the ignored listings entry by entry in bash. It cost about 2.3 s
per attempt at 20,000 ignored files, so the `comm` fast path replaced it. The bash
merge is kept only for names that contain a newline, where `comm` is not exact.
Not measured: coder and application test time, ignored trees larger than 20,000
files, and Linux.

### Validation (second continuation, observed in this session)

- Baseline before any edit: `bash scripts/test_loop.sh` at `7496c6f`: **56/56 cases,
  56/56 regressions, exit 0**.
- Final: `bash scripts/test_loop.sh` on the final files: **63/63 cases, 63/63
  regressions, exit 0**. The seven added cases are `index-flags-both`,
  `index-flag-both-startup`, `judge-flag`, `ignored-protected`, `quoted-discard`,
  `newline-discard`, `plusplus-note`.
- The seven added cases fail on the HEAD runner for their stated reasons (see the
  table). The `index-flags` and `index-flags-skip` cases now also assert that coder-set
  flags never reach the judge; their mutants (removing the post-coder clear) are
  caught on that assertion.
- The ignored-file merge was checked with a property test outside the repository:
  200 random trials in each of four environments (ambient `en_US.UTF-8`, `LC_ALL=C`,
  `LC_ALL=en_US.UTF-8`, `LANG=en_US.UTF-8`), half of them with names that contain a
  newline, against a naive reference. **0 mismatches** in every environment.
- `tests/run.sh` (Go toy kit, `GOPROXY=off`, `GOTOOLCHAIN=local`, temporary `GOCACHE` and
  `GOMODCACHE`): 13 `ok`, exit 0.
- `python3 -I tests/test_install.py`, `tests/test_kit_format.py`,
  `tests/test_runner_config.py`: exit 0 each.
- `bash -n` and `/bin/bash -n` on `scripts/loop.sh`, `scripts/test_loop.sh`,
  `scripts/install.sh`, `tests/run.sh`, `tests/fakecoder.sh`: passed. `git diff --check`: clean.

Environment limits: Bash 3.2.57 on arm64 macOS only; GNU `timeout`, Linux and CI were
not run; not run as root; no live coder and no model call. The fixtures were in
`/tmp`, and the property test and performance harness are not committed.

### Second continuation: open items

- **Deferred decision 16 (new).** On an attempt-mode git failure, the run stops
  with the attempt's changes left in the worktree (observed, finding 6). The clean-start
  gate then refuses the next run, so the failure is loud and nothing is committed. A
  change would discard attempt-owned work after a failed git command, which is the
  attempt-discard policy (decision 6). Owner choice.
- **Decision 14 and decision 15** are unchanged in substance. Decision 15 now also covers
  pre-existing ignored files the attempt deleted.
- **Clean-start gate and `ARTICLE-DRAFT.md`.** The untracked `ARTICLE-DRAFT.md` makes
  the clean-start gate refuse any real run in this checkout. It was not added, ignored
  or moved. Whether to ignore or move it is an owner decision.

## Third continuation from `3473942`: review-4 findings

Source: the read-only review of the continuation head (private result
`continuation/runner-review-4.json`; its verdict and finding text were read, and
no other fields). The reviewer ran no commands and made no edits, and it is of the
same model family as the writer. It is an input to this work, not an independent
review of the changes below. Its findings were treated as hypotheses. Each was
reproduced first on the HEAD runner (`3473942` `scripts/loop.sh`, the same bytes as
the second continuation's final file, SHA-256 `9b4d6053…`) in disposable fixtures
under `/tmp/rl-exp4`, with a scripted fake coder and no model. Each new regression
case was also run on the HEAD runner and fails there for its stated reason.

| # | Finding | Reproduced on `3473942` | Disposition |
| --- | --- | --- | --- |
| R1 (rated low) | Index flag on a tracked file whose name starts with a newline is missed. The `ls-files -v` listing was split into lines; `sed` printed an empty path; `update-index -- ""` printed `Ignoring path` and exited 0, so the flag stayed. Startup did not refuse (rc 2 after three attempts, not rc 1). An attempt that set the flag and edited the file passed (`T1 passed`) and committed, while the committed `\nverify.sh` still said `exit 1`. | **Yes, and worse than rated:** the commit passes while its own protected test fails. | **Fixed.** Names are read NUL-delimited (`grep -azE` on `ls-files -v -z`); the startup, clear and judge checks use those records. Cases `newline-index-flag-startup` and `newline-index-flag`. |
| R2 | After `.gitignore` is restored, nothing confirms that `.loop/` is still ignored. A rule outside `.gitignore` (here `.git/info/exclude`) keeps hiding it. | **Yes.** With the exclude rule removed, the restore did nothing, `git clean -fd` deleted `.loop/` (its `loop.log` was lost), and the run died with `could not list ignored files` (rc 1). Nothing was committed. | **Fixed.** A check right after restoration stops the run, with state kept, before anything is judged or committed. Case `ignore-rule-outside`. |
| R3 (hypothesis 1) | A judge that passes with no change to commit makes `git commit` fail with `nothing to commit`. The run exits 1 and logs nothing about the attempt. | **Yes.** rc 1, no commit, no pass or failure line. | **Fixed.** A pass whose judged tree equals HEAD is logged as a failed attempt, so it counts toward `MAX_ATTEMPTS`. Case `empty-pass`. This is a choice; decision 17. |
| R4 (hypothesis 2) | A run started in a subdirectory: protected-path listings and pathspecs are relative to the current directory. | **Yes, but fail-closed.** An untracked protected root file (`loop.sh`) was refused by `protected_in_tree` (rc 3, no commit). A modified tracked protected root file (`SPEC.md`) made restoration fail (rc 1, no commit, the edit left in the worktree). | **Fixed.** A run not at the repository top level is refused at startup, before any state is created. Case `subdir-start`. Check-only modes are not affected. |
| R5 (hypothesis 3) | A protected file written and restored within the judge window is invisible to the end-state comparison. | Not reproduced. This is the window that decision 14 option (c) would close. | **Not changed.** Decision 18. |
| R6 (hypothesis 4) | A surviving descendant can write after a timeout. | Not re-tested here. | **Not changed.** Deferred decision 2. |
| R7 (hypothesis 5) | `10#` on a very long count overflows: in bash 3.2, `99999999999999999999 + 1` evaluates to `-8446744073709551616`. | Arithmetic checked; the loop was not run with that state. | **Not changed.** The counter is in the coder-writable `.loop/` (decision 8), and the coder can already write `0`, which resets escalation. The overflow adds no new effect. |

Behaviour changes a reader should know about:

- Startup refuses a run started outside the repository top level.
- A file whose name starts with a newline is refused at startup when its index flag
  is set, and cleared during an attempt like any other flagged file.
- A pass that leaves the tree unchanged is a failed attempt, not a stop with a git error.
- If `.loop/` is still not ignored after `.gitignore` is restored, the run stops (with
  its state kept) instead of deleting `.loop/` through `git clean`.

Known limit (not tested): a name that contains a newline followed by `h`, `s` or `S`
and a space can be reported as flagged when it is not. The effect is a startup
refusal or a failed attempt. It never lets a change pass, and it never misses a real
flag.

### Performance (third continuation)

Attempt path: one passing attempt with a fake coder (`/tmp/rl-exp4/perf4.sh`, not
committed), disposable repositories, three runs each, `maintenance` default. The
machine was shared with an unrelated loop process (load average about 3.5), so these
numbers are indicative only.

| Ignored files | `3473942` (s) | Working tree (s) | Difference (median) |
| ---: | --- | --- | ---: |
| 0 | 0.300, 0.299, 0.301 | 0.327, 0.325, 0.323 | about +0.025 s |
| 20,000 | 0.431, 0.450, 0.451 | 0.471, 0.483, 0.452 | about +0.02 s |

The added work per attempt is two `git check-ignore` calls (one per restoration), one
`git rev-parse` for the no-change test, and an index-flag listing scanned with `grep -z`
instead of `sed`. At startup there is one `git rev-parse --show-prefix`. Check-only
modes do not run the new startup guard, the flag clearing or the restoration, so they
are unchanged by construction; they were not timed. Not measured: coder time,
application test time, ignored trees larger than 20,000 files, and Linux.

### Validation (third continuation, observed in this session)

- Baseline before any edit: `scripts/test_loop.sh` at `3473942` run from a scratch copy
  of the HEAD `scripts/loop.sh` and `scripts/test_loop.sh`: **63/63 cases, 63/63 regressions, exit 0** (19 min 38 s; `/tmp/rl-exp4/suite-baseline.log`).
- Final: `bash scripts/test_loop.sh` on the working tree: **68/68 cases passed, 68/68
  regressions caught, exit 0**, 23 min 32 s wall time (`/tmp/rl-exp4/suite-full.log`).
- The five new cases fail on the HEAD runner for their stated reasons: `newline-index-flag-startup`
  (rc 0, expected 1), `newline-index-flag` (rc 0, expected 2: the committed test fails),
  `ignore-rule-outside` (no "still not ignored" message), `empty-pass` (rc 1, expected 3),
  `subdir-start` (rc 2, expected 1). Each passes on the fixed runner.
- Each new case has a mutant (the old behaviour re-introduced in a disposable copy); every
  mutant is caught. The three existing index-flag mutants were repointed to the new code.
- `tests/run.sh` (Go toy kit, `GOPROXY=off`, `GOTOOLCHAIN=local`, temporary `GOCACHE` and
  `GOMODCACHE`): 13 `ok`, exit 0.
- `python3 -I tests/test_install.py`, `tests/test_kit_format.py`, `tests/test_runner_config.py`: OK each.
- `bash -n` and `/bin/bash -n` on `scripts/loop.sh`, `scripts/test_loop.sh`, `scripts/install.sh`,
  `tests/run.sh`, `tests/fakecoder.sh`: passed. `git diff --check`: clean.

Environment limits: macOS `/bin/bash` 3.2.57 (arm64) only; BSD `grep -z`; GNU `grep`,
GNU `timeout` and Linux were not run; not run as root; no live coder, no kit and no model call.
Only the fake coder in `/tmp` fixtures was used.

### Third continuation: open items

- **Decision 17 (new).** Should a pass that leaves the tree unchanged count as a failed
  attempt (current, R3), or end the run as complete because the task already passes?
  Owner choice.
- **Decision 18 (new).** Should judging also detect protected writes made and restored
  within the judge window (R5)? Options as in decision 14 (c): judge in a clean export,
  or accept the gap.
- Review-4's reviewer and this writer are the same model family. No independent review
  of this commit has been run. The findings it raised are answered here, not verified by
  an independent reviewer.

## Fourth continuation from `623e758`: review-5 findings

Source: the read-only review of the continuation head (private result
`continuation/runner-review-5.json`; its verdict and finding text were read, and no other
fields). The reviewer ran nothing and made no edits. It is of the same model family as
the writer, so it is an input to this work, not an independent review of the changes below.
Its findings were treated as hypotheses. Each was reproduced first on the HEAD runner
(`623e758` `scripts/loop.sh`, SHA-256 `0fe0f14b…`) in disposable fixtures under
`/tmp/rl-exp5` (`/tmp/rl-exp5/bin/repro.sh`, not committed), with a scripted fake coder and
no model. Each regression case added here was also run on the HEAD runner and fails there
for its stated reason.

| # | Finding | Reproduced on `623e758` | Disposition |
| --- | --- | --- | --- |
| C1 (medium) | Protected matching is line-based. A pattern that spans a newline cannot match a name containing one, so the file escapes restoration. | **Yes.** `^testdata/.*\.golden$` and a coder that creates `testdata/a<LF>b.golden` and passes the test: rc 0, the file is committed. | **Fixed.** `is_protected` matches the complete name with `[[ =~ ]]`, the same ERE syntax. A status 2 fails the run rather than leaving a name unprotected. Used for restore, removal of attempt-created ignored files and the judged-tree check. Case `newline-protected`; its mutant restores the grep form. |
| C2 (medium) | A protected file that git ignores and that existed before the attempt is not restored. The coder edits it in place and the judge passes on that edit, which no commit contains. | **Yes.** Coder rewrites the ignored `testdata/x.golden` to pass: the worktree passes and the run prints `every task passes` with rc 0, while **nothing is committed**. The success was computed on the worktree, not on any commit, so the message is wrong. | **Fixed by refusal.** Before the coder is launched (and before the attempt is counted), a run stops if any git-ignored path matches a protected pattern. The alternative, restoring such files from a copy, is deferred decision 20. Case `ignored-protected-preexisting`. |
| C3 (low) | A run that starts with every task passing exits 0 with `every task passes`, but `format_check` and `check` never run. | **Yes.** `format_check` set to `false` and an already-passing task: rc 0, `format_check` did not run. | **Message corrected.** A run that commits nothing logs `every task passes; format_check and check were not run (run --check to run them)`. The exit status is unchanged. Whether such a run should run the gates is deferred decision 19. Case `all-pass-start`. |
| C4 (low) | The formatter runs on a timed-out coder's partial output. | **Yes.** The coder wrote `code` and timed out: `.loop/format-runs` was written, so the formatter ran. | **Fixed.** The formatter runs only while the attempt is still `ok`. Case `format-after-timeout`. |
| H1 | Artifacts created by the judge before the attempt (during `first_failing`) are treated as pre-existing and kept on discard. | Not reproduced. Needs a test whose artifact only appears on failure. | **Not changed.** It is an instance of decisions 14 and 15 (ignored files), and is contrived. |
| H2 | A `git commit` failure after a judged pass stops the run with the judged changes staged. | Not reproduced. | **Not changed.** The run fails loudly; this is the family of deferred decision 16. |

Behaviour changes a reader should know about:

- A protected pattern now matches the complete file name. A name that contains a newline
  is matched as one name. A name such as `x<LF>PROMPT.md` was protected before only
  because its second line matched; it is a different file and is not protected now.
- A run stops with exit 1 before any coder launch when a protected path is git-ignored
  before the attempt. The message names the first such path. This also covers a protected
  ignored file that the kit's own test commands created before the attempt began; such a kit
  now stops instead of running.
- A run that starts with every task passing logs that `format_check` and `check` were
  not run. Its exit status is still 0.
- A formatter does not run after a coder timeout.

### Performance (fourth continuation)

Attempt path: one passing attempt with a fake coder per run (`MAX_ITER=1`, so the run stops
at the cap after its commit; the commit count was spot-checked on sample runs of each scenario, not on every run). Disposable
repositories under `/tmp/rl-exp5`, three runs each, `/tmp/rl-exp5/bin/bench.sh` (not committed).
The machine was shared with an unrelated running loop, so these figures are indicative.

| Files the attempt touches | `623e758` (s) | Working tree (s) |
| --- | --- | --- |
| none | 0.367, 0.378, 0.384 | 0.382, 0.396, 0.378 |
| 2,000 untracked files created by the coder | 14.935, 14.644, 16.651 | 0.775, 0.914, 0.851 |
| 20,000 git-ignored, unprotected files present before the attempt | 0.566, 0.538, 0.604 | 1.149, 1.124, 1.154 |

The HEAD figures were taken on an earlier run; the working-tree figures are from the final
`loop.sh` (SHA-256 `7af8f469…`). A first working-tree run before the subshell fix (below) gave
0.365/0.401/0.360, 0.791/0.681/0.719 and 1.199/1.119/1.182 s.

Matching a changed name no longer starts a `grep` process per name, which made the 2,000-file
attempt about 17 times faster (median 14.9 s to 0.85 s). The new refusal checks every
pre-existing ignored name once per attempt in bash: about 0.6 s at 20,000 names (roughly
30 µs each), growing linearly with the number of ignored files. With no ignored files it
adds no measurable time.

Orchestration benchmark (`tests/benchmark_loop.py`, 40 no-op tasks, three runs each):

| Runner | `--check-once` median (runs) | `--check` median (runs) |
| --- | ---: | ---: |
| `623e758` (run back to back with the next row) | 0.555 s (0.585, 0.555, 0.554) | 6.394 s (6.572, 6.296, 6.394) |
| working tree (final `loop.sh`) | 0.568 s (0.568, 0.544, 0.587) | 6.282 s (6.265, 6.424, 6.282) |

Check-only modes call none of the changed functions. In this paired run the medians differ by
less than the run-to-run spread (the first pair, taken earlier on the same shared machine, gave
0.543 s and 6.559 s for `623e758`, and 0.565 s and 7.025 s for the pre-fix working tree). This is
not a measured regression, and it does not prove that check timing is unchanged.

Not measured: coder time, application test time, Linux, GNU `grep` and `timeout`, ignored trees
larger than 20,000 files, and the cost of a protected file that the attempt itself creates.

### Validation (fourth continuation, observed in this session)

- Reproduction on `623e758`, before any edit: C1 to C4 each reproduced (table above). Observed:
  C1 committed `testdata/a<LF>b.golden` with rc 0; C2 printed `every task passes` with rc 0 and
  committed nothing (the pass came from the worktree, which still held the coder's edit to the
  ignored file; the committed tree was not tested); C3 exited 0 and `format_check` did not run; C4 ran
  the formatter on the timed-out output.
- Each new case fails on the `623e758` runner for its stated reason: `newline-protected`
  (got 0, expected 2), `ignored-protected-preexisting` (got 3, expected 1), `all-pass-start`
  (the message is absent) and `format-after-timeout` (the formatter ran). Each passes on the
  working tree.
- Each new case has a mutant, a disposable copy with the old behaviour restored. All 72 mutants
  were caught in the final run. The `formatted`, `custom-tasks-*` and `ignored-protected-preexisting`
  mutant anchors were updated to the new text. A first full run stopped at the `custom-tasks-*` anchor (`mutation anchor
  absent`, `EXIT=1`, `/tmp/rl-exp5/suite-1.log`). That run is not counted.
- Self-review before the final run found one defect in my own change: the refusal called
  `first_protected` inside `$( )`, so a `die` in that subshell would not stop the run. It is
  now a direct call that sets `PROTECTED_FOUND`. The status-2 branch of `is_protected` is
  defensive only: I probed candidate patterns on this machine and found none that grep accepts
  and bash rejects, so no regression exercises it. Its code path was not run.
- `bash scripts/test_loop.sh` on the final files (`scripts/loop.sh` SHA-256 `7af8f469…`,
  `scripts/test_loop.sh` SHA-256 `fa42cf9f…`): **72/72 cases passed, 72/72 regressions caught,
  exit 0** (`/tmp/rl-exp5/suite-3.log`). An earlier run on the pre-fix runner (`aef6a196…`,
  `/tmp/rl-exp5/suite-2.log`) also passed 72/72 and is superseded. The four new cases are
  `newline-protected`, `ignored-protected-preexisting`, `all-pass-start` and `format-after-timeout`.
- `python3 -I tests/test_install.py`, `tests/test_kit_format.py` and `tests/test_runner_config.py`
  on the final files: each exit 0 (`OK`).
- `tests/run.sh` (Go toy kit) with `GOPROXY=off`, `GOTOOLCHAIN=local` and temporary `GOCACHE` and
  `GOMODCACHE` on the final files: 13 `ok`, exit 0.
- `/bin/bash -n` on `scripts/loop.sh`, `scripts/test_loop.sh`, `scripts/install.sh`, `tests/run.sh`
  and `tests/fakecoder.sh`: passed. `git diff --check`: clean.
- Whole-name matching was compared with the old line-based grep on sample names
  (`/tmp/rl-exp5/bin/matcher.sh`). The two names that differ are `x<LF>PROMPT.md` (now not
  protected, correct: a different file) and `testdata/a<LF>b.golden` (now protected, correct).
- Hashes of the HEAD runner (`623e758`): `scripts/loop.sh` `0fe0f14b…`.

Environment limits: macOS `/bin/bash` 3.2.57 (arm64) only; no GNU `grep`, GNU `timeout` or Linux;
no live coder, no real kit and no model call; the fixtures and benchmarks were in `/tmp` and
are not committed. No independent review of these changes has been run.

### Fourth continuation: open items

- **Decision 19 (new).** A run that starts with every task passing runs no `format_check`
  or `check`. Should it run them and exit non-zero on failure, or keep the current
  message? Owner choice.
- **Decision 20 (new).** A protected path that git ignores before an attempt now stops
  the run. Alternative: restore such files from a content copy taken before the coder
  runs, which keeps the run usable but adds a copy per attempt and needs a symlink-safe
  restore. Owner choice.
- Review-5 was made by the same model family as the writer. No independent review of
  these changes has been run, and this session cannot run one (it may not start a model).

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

- Second continuation: set both flags, then have a judge command set one and edit the file;
  a formatter that sets a flag. Confirm the attempt fails and the file is restored.
- A failed attempt that creates an ignored file with a non-ASCII name, a quote, a backslash
  and a newline in its name. Confirm each is removed, and that a file that existed before
  the attempt is kept.
- A `.gitignore` edit that hides a protected pattern. Confirm the new file is removed before the judge.
- A note line that begins with `++`. Confirm it reaches `.loop/notes.<id>`.

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
15. **New.** A discarded attempt removes ignored files it created, but does not restore pre-existing ignored files it modified or deleted in place. Options: keep a content copy of ignored files (cost grows with their size) or accept the gap.
16. **New (second continuation).** An attempt-mode git failure while snapshotting (finding 6) stops the run with the attempt's changes left in the worktree. Discarding them automatically is the alternative; it changes the attempt-discard policy (decision 6). Owner choice.
17. **New (third continuation).** Should a pass that leaves the tree unchanged count as a failed attempt (current; R3), or end the run as complete because the task already passes? Owner choice.
18. **New (third continuation).** Should judging detect protected writes made and restored within the judge window (R5)? Options as in decision 14 (c). Owner choice.
19. **New (fourth continuation).** Should a run that starts with every task passing run `format_check` and `check` (and fail if they fail)? Current: no; it logs that they were not run and exits 0. Owner choice.
20. **New (fourth continuation).** A git-ignored protected path that exists before an attempt stops the run (current). The alternative is restoring it from a content copy before the coder runs. Owner choice.

## Source state

- Continuation base: `816f36f`. Branch: `overnight-reliability-performance`. The continuation commit is recorded in `git log`; `main` was not touched.
- Earlier rounds: base `a1f9daa`, prior commit `ed40ea0`.
- Changed files in the continuation: `scripts/loop.sh`, `scripts/test_loop.sh`, `SKILL.md`, `README.md`, `references/development-review.md`.
- Continuation SHA-256 (working tree at the time of the final suite run): `scripts/loop.sh` `faefa253dff9fe6e728075f01a0f8a6a50a147066f9da3db7af85b72a9f582dd`; `scripts/test_loop.sh` `0a4aaf2300c92586d8cab20a1c12bf52b526316ddec0ea785a6915b61b54603c`.
- Earlier-round hashes: `scripts/loop.sh` at `816f36f` `a24c5348…`, at `a1f9daa` `232a5c0a…`; `scripts/test_loop.sh` at `816f36f` `bbe9e3df…`. All verified against blobs in git history.
- Second continuation (base `7496c6f`, final files, after the last suite run):
  `scripts/loop.sh` `9b4d60534e01287ba4f80508c1068287081397a196fbb82a074de19ec6260baf`;
  `scripts/test_loop.sh` `a013e22a3a2405da7c95795414afda414e20e8a6152720a22497a30a4abd9706`;
  `SKILL.md` `052009200d3fdeb55518d983c6283562ad470a5dcbc3c9eda49143f441ec504b`;
  `README.md` `f6dfd0774e309c08302c81828c75404b442a3bc2fce575e00967bebfc9622e6a`.
- Baseline `scripts/loop.sh` SHA-256 at `a1f9daa`: `232a5c0a35496f10e791ab164f0a12b9760e9260025017252d53f9bb6f7097a1`.
- Third continuation (base `3473942`, final files): `scripts/loop.sh` `0fe0f14b13c12e0a2b19295f55147c444db5390ac7fab9e9b24e7616d2021e64`; `scripts/test_loop.sh` `3e97dc7fe4f93ceb4002704f019904f1eeed705f8f2240748d9e4a2c69549a2f`. Changed: `scripts/loop.sh`, `scripts/test_loop.sh`, `SKILL.md`, `README.md` (count only), this report.
- Fourth continuation (base `623e758`, which follows `816f36f`): changed files `scripts/loop.sh`,
  `scripts/test_loop.sh`, `SKILL.md`, `README.md` (case count), this report. SHA-256 of the final
  files (the validated 72-case run): `scripts/loop.sh` `7af8f469281773f415ae6edf8f613e13c1bf1a17f7282c8cf8b535d9e46328e7`;
  `scripts/test_loop.sh` `fa42cf9fbd67506d3bb08390793fd3b1305de1957bc29fa708498d2b0e0429e3`.
  The commit is recorded in `git log`.
- Untracked `ARTICLE-DRAFT.md` left untouched and not committed.
- Not merged to `main`; pending independent review. No remote operation.

## Unrelated activity noticed

During the first round of work, a `scripts/loop.sh --check` run in
`/Users/rob/Development/drift` from another session was active (PID 35018). I did
not inspect, stop or touch it, or that repository. Not observed in this round.

During the fourth continuation, `ps` showed two other `scripts/loop.sh` processes that are not
this repository's: one started by `run-loop.sh` under `/Users/rob/Development/drift-loop-eval/run26-stage6a2`,
and one whose working directory (read with `lsof`) is `/Users/rob/Development/makeready/tools/comps`.
I did not read, stop or touch either. Their working directories are other repositories, so
they are not writers to this one as far as I observed; what they do in their own repositories is unknown.
