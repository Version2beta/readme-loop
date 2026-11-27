# readme-loop

**Agree through the README. Implement freely. Accept through behavioral evidence.**

readme-loop is a coding-agent skill for building and extending software from an
agreed user-facing contract. Its objective is minimum total engineering cost and
time to an appropriate, demonstrable level of correctness—not minimum coder
spending or maximum verification volume.

Version 0.2.0 is a development release, not a production-ready release. The
workflow is independent of spec-loop and does not require its kit format or
runner.

## Install and start

Clone this repository and install for your chosen host:

```sh
git clone https://github.com/Version2beta/readme-loop.git
cd readme-loop
bash scripts/install.sh --pi       # or --claude or --codex
```

| Host | Installed directory | Invocation |
| --- | --- | --- |
| Pi | `~/.pi/agent/skills/readme-loop` | `/skill:readme-loop` |
| Claude Code | `~/.claude/skills/readme-loop` | `/readme-loop` |
| Codex | `~/.agents/skills/readme-loop` | `$readme-loop` |

The installer needs Bash and copies files only. It refuses existing destinations,
including symlinks; it does not install dependencies, change host settings, start
models or overwrite installed user work. Updating an installed copy remains
manual. Installing from a clone gives that clone's revision, not an assurance
that GitHub contains unpublished local changes.

Start a fresh agent session **in the project being built**, then ask:

```text
/skill:readme-loop Build the software promised by my README. Resolve only
consequential gaps, then implement and evaluate the full agreed scope.
Use internal milestones without stopping for approval after each one.
```

Use the invocation for your host. These are agent requests, not shell commands.
An existing approved README/scope does not need ritual reapproval. Discovery or
README approval alone still does not supply execution permissions; obtain any
missing authority once, not again at each internal milestone.

## The normal workflow

1. **Agree.** Discover root/module READMEs, resolve consequential ambiguity and
   establish the entire requested scope. Keep implementation freedom explicit.
   Separate existing behavior from desired promises and explicit future deferrals.
   Do not substitute a smaller checkpoint for a whole-product request. Before
   coding, check that every required acceptance step can run in its intended
   environment. Ask in one message for missing consequential permissions or
   resources, and raise newly discovered blockers promptly.
2. **Establish acceptance.** The acceptance owner derives meaningful behavioral
   checks from the contract, including consequential failures and prohibited
   effects. Check that tests run and reject relevant incorrect behavior. Keep
   accepted evaluation outside the implementer's authority to weaken.
3. **Implement.** Complete the agreed scope with ordinary coding tools. Internal
   milestones organize progress but do not require repeated approval or trigger
   partial delivery. Retain useful context, run focused checks while editing and
   avoid fresh-agent microtasks. Production architecture belongs to the implementer.
4. **Evaluate.** Run each required acceptance check once on the candidate, using
   public interfaces and representative examples. Repeat only to investigate
   instability, ordering or concurrency—not as an automatic quadratic gate.
5. **Review and deliver.** Use one bounded independent review when authorized,
   batch corrections and verify them. Deliver evidence, total economics and
   limitations. Serious unresolved defects block acceptance; minor findings do
   not automatically start another broad review loop.

One invocation owns the work through the full agreed completion boundary,
including evaluation, review and necessary corrections. Stop early only for an
explicitly requested partial delivery, a real execution/budget limit, or a
consequential contract/authority blocker. Report that state as partial or blocked,
not complete. A green internal checkpoint is not a reason to hand work back.

The operational instructions are in [SKILL.md](SKILL.md). This is an agent-guided
workflow, not a README watcher or background orchestration service.

### What is not mandatory

A separate `SPEC.md`, private reference implementation, supplied stubs, task
manifest, copied runner, extra agents and elaborate evidence packets are **not
entry requirements**. Use existing project commands and records. Module READMEs,
precise supporting schemas and additional qualification are useful only where
they remove material uncertainty.

An optional reference or small independent oracle may repay its preparation
cost on difficult or repeatedly implemented behavior. Its existence does not
prove the requirements are right or exclude correlated defects.

## Incremental development

The README is a living contract. Use the same workflow to add, change, clarify
or retire requirements in an existing project. Compare the previously accepted
contract, the current README and the implementation to identify what actually
changes, what stays the same and what was never fulfilled.

Reuse decisions, implementation and acceptance checks where they still apply.
Establish independently owned acceptance for new or changed behavior before
implementation, preserve unchanged obligations, and check for regressions where
existing behavior is affected. Removing a promise is not by itself permission
to remove working functionality, break compatibility or delete data.

Complete the entire agreed increment in one invocation. In the handoff,
distinguish newly verified behavior from earlier evidence, outstanding
requirements and regressions. See
[the skill instructions](SKILL.md#incremental-development).

## Single-pass checks

Prefer native commands. The optional helper requires Python 3.9+, Bash and a
POSIX system; it introduces no third-party packages:

```sh
python3 /path/to/readme-loop/scripts/check.py \
  --cwd /path/to/project --timeout 300 -- \
  'go test -race ./...' \
  'go vet ./...'
```

Each quoted argument is one trusted shell command. Commands run in order, at
most once each; a failure stops later checks. `--timeout` is a positive finite
per-command limit in seconds, not a global deadline or spending control. Exit
0 means all supplied commands exited 0; timeout is 124, invalid invocation is 2,
and interruption exits 128 plus the signal number. Other command failures retain
their exit status (signal deaths use 128 plus the signal number). These codes can
overlap: a command that itself exits 124 also returns 124. The `FAIL`, `TIMEOUT`
and `INTERRUPTED` diagnostic labels distinguish those outcomes.

The helper does not call models, format, commit, discard, create logs or decide
which tests establish acceptance. Commands inherit process permissions and may
write files or use the network; this is **not a sandbox**. On timeout/interruption
it terminates the command's process group, but descendants that escape that
group are not contained. Cleanup keeps the group leader unreaped through the last
signal to avoid reusing its process-group identity. On macOS, `ps` is used to
confirm the kernel's zombie-only-group `EPERM` case; a live or uninspectable group
still reports cleanup failure rather than silently ignoring permission errors.
On normal command exit, background services are not stopped automatically;
commands must own their cleanup. Run only authorized
checks in an appropriate workspace. Verify collection and source state separately; a no-tests exit 0 is not qualified
behavioral acceptance. Do not put secrets in command arguments or test output.

## Authority, safety and useful evidence

README approval is not permission for paid calls, extra agents, commits,
discards, installation, remote changes or production access. Honor existing
explicit permissions, preserve user work and stop affected work when additional
authority is needed. Establish authorized billing routes, models, spending
controls and stop conditions before paid work. Reuse applicable answers,
including owner-confirmed external caps; do not ask for a duplicate cap.
Do not bypass host permissions.

Acceptance must cover meaningful effects without fixing incidental architecture.
Path protection is not process isolation. Security-sensitive or destructive
software needs verification and isolation appropriate to its consequences;
lightweight does not mean an unresolved safety defect can be accepted.

Record preparation, implementation, evaluation/review and correction cost/time
where available. Distinguish active work, idle waits and operator effort.
Unavailable values are unknown, not zero. Separate reported spending from
estimates and reservations. No claim of economic superiority follows from a
cheap coder run or a no-op benchmark.

## Local validation

Fast checks for packaging and the single-pass helper:

```sh
python3 tests/test_install.py
python3 tests/test_check.py
```

They use disposable directories and scripted commands, not models. The check
helper has no application-stage benchmark yet. Packaging and local command tests
do not establish live host behavior, application correctness or lifecycle savings.
CI is configured to run the packaging and helper checks on Linux and macOS,
including a Python 3.9 job on Linux.

### Historical runner

The archived [kit format](references/kit-format.md) and
[protected-surface template](references/protected-surface.md) describe the old
runner, not the current workflow. The distribution still contains the runner
and fixtures, but this release does not promise v0.1 interface or workflow
compatibility. The old runner's repeated-task `--check` is not an acceptance
requirement for readme-loop.

To test the old runner separately:

```sh
python3 tests/test_kit_format.py
python3 tests/test_runner_config.py
bash scripts/test_loop.sh
bash tests/run.sh
```

They require Git, jq, Python 3 and timeout/gtimeout; the toy suite also requires
Go and Perl. Mutation preparation uses a guarded literal byte replacement rather
than Bash 3.2's slow multibyte pattern replacement. All real/mutated cases retain
their assertions, each case has a 45-second outer deadline, and outer timeouts do
not qualify a mutation as caught. CI separates fixture and toy steps, reports
case progress, and caps the legacy job at 15 minutes. The
[development review](references/development-review.md) records earlier
maintenance and limited benchmarks, not validation of the current workflow or a
comparative result.

## Decisions and status

| Decision | Rationale | Status |
| --- | --- | --- |
| Develop readme-loop independently from spec-loop and SIE. | Keep its scope and costs accountable to this workflow. | Approved |
| README-first; independently owned behavioral acceptance; implementation freedom. | Preserve the useful distinction between intent, implementation and success. | Approved |
| Lightweight default; references, kits and stronger verification justified by risk/reuse rather than universally required. | Optimize total engineering effort and time to value. | Approved |
| Native checks, single-pass acceptance, bounded review/correction. | Remove routine repetition without treating incomplete evidence as success. | Approved |
| One invocation completes the entire agreed scope; internal milestones are not automatic approval or delivery gates. | Preserve autonomous responsibility rather than stopping at the first working subset. | Approved |

The skill documents the workflow for both new builds and incremental changes.
Automated checks exercise packaging, installation and the optional single-pass
helper without calling models. End-to-end acceptance in a live agent session,
including on an existing project, still awaits empirical validation. No
controlled framework comparison or measured end-to-end speedup is claimed.
Existing installed copies are not automatically updated.

## Background

[Readme Driven Development](https://tom.preston-werner.com/2010/08/23/readme-driven-development.html)
provides the starting idea: explain what the user should get before building it.
Readme-loop adds independently owned behavioral acceptance and bounded execution,
not a requirement to implement the product twice.
