---
name: readme-loop
description: Build or extend a tool from author-approved root and module READMEs, derive and privately verify bounded implementation kits, then use the spec-loop runner for test-judged coding. Use when asked for readme-loop, a README-first design or kit, or to run, review, or fix a readme-loop stage.
license: MIT
metadata:
  version: "0.1"
---

# Readme-loop

Write the README first. Agree on what it promises. Then build the software
that fulfills those promises. The strong model (you) helps refine the design,
proves a bounded assignment is achievable, and returns to the author between
kits. The coding model implements one task at a time from files alone.

`/readme-loop` names this workflow, defined by this file. In Claude Code,
install this directory under `~/.claude/skills/readme-loop`, restart, and invoke
`/readme-loop` followed by the request. In Pi the explicit skill command is
`/skill:readme-loop`, optionally followed by the request. In Codex, install
under `~/.agents/skills/readme-loop` and invoke `$readme-loop` (or select it
from `/skills`). The bundled installer supports `--claude`, `--pi`, and
`--codex` without modifying agent settings.
Resolve bundled paths relative to this skill directory, not the tool's repo.
Read [references/kit-format.md](references/kit-format.md) before preparing a
kit and the header of [scripts/loop.sh](scripts/loop.sh) before running it.
The runner is spec-loop's, unchanged in kit fields and attempt judging, plus
one read-only addition: `--check-once` for fast kit verification, and cached
fixed-task metadata to reduce process overhead. The kit
format adapts its authoring guidance without changing runner fields.

## Roles and authority

| Role | Does | Never does |
| --- | --- | --- |
| Owner / author | Supplies or approves READMEs; decides purpose, scope, language, models, spending, consequential actions; uses the result | |
| Strong model (you) | Clarifies promises; maintains decisions; prepares tests, seams, stubs, tasks, and private reference; verifies and reviews | Ships an unverified kit or invents author approval |
| Coder | Implements one bounded task; records findings in progress notes | Edits approved READMEs, supporting contracts, tests, fixtures, complete files, task definitions or runner; commits; marks work done |
| Runner | Selects tasks; restores protected paths; judges; performs authorized commits or discards | Trusts coder claims or an exit code alone |

Loading this skill, writing a README, or approving a design is not permission
for model calls, spending, an implementation loop, commits, discards, remote
changes, or production access. Obtain explicit permission for each applicable
consequential action. Preserve all pre-existing user work. Commit only with
explicit authorization; discard only attempt-owned changes with explicit
authorization. The clean-start gate is not permission. The unchanged runner
automatically commits passing attempts and discards failing attempts: without
both permissions, do not launch it. Never run a real kit just to test the loop.

Protected paths and Git checks constrain accepted changes, not process access.
The coder can execute commands with its process permissions. Prefer an
isolated environment containing only necessary credentials, and provider-side
spending limits sized to the risk. Do not substitute guardrail infrastructure
for the cheapest useful feasibility experiment.

## Where you are working

- **Owner's repository:** prepare the kit on an authorized branch, preserve
  existing work, and verify it there. The owner can later launch from that
  checkout with the required permissions.
- **Separate sandbox:** prepare and verify there; deliver a zip (later stages:
  an overlay zip). State that an overlay checked only against the private
  reference has not been checked against the owner's loop-written code.

## Two nested loops

The **design loop** is author-facing: refine READMEs, obtain real inline
approval, prepare a bounded kit, review evidence, and decide the next step.
The **implementation loop** executes that verified kit unattended inside its
approved boundaries. There is no separate automated design runner. Return
to an author-review intermission between kits; do not chain kits past review.

Refine the whole picture before over-detailing one module. Order decisions by
how much work they constrain and the cost of reversing them. Persisted data
formats may belong early; a local sorting algorithm can usually wait.

| Level | Establish | Author-review gate |
| --- | --- | --- |
| Outline | Users, useful workflows, examples, non-goals, important constraints | Is this the tool the author wants? |
| Structure | Module responsibilities, interfaces, data ownership, effects, failures; walk workflows across boundaries | Are boundaries coherent and consequential choices approved? |
| Skeleton | A thin useful end-to-end case through real interfaces, explicit limitations; test risky assumptions first | Does executable evidence support the design, or must READMEs change? |
| Detail | Further workflows, edge cases, integrations, necessary performance work | Does added detail preserve the approved contract? |

These are review gates, not four mandatory kits. Even a skeleton kit needs
failing-stub, passing-reference, and runner-judge verification. An approved
outline is not feasibility evidence; a passing skeleton is not the whole tool.

## 1. Discover, clarify, and frame the finished-tool READMEs

Begin in the owner's project, not this installed skill directory. Use a project
path supplied by the owner; otherwise use the current working directory. If
that location is ambiguous, ask before inspecting another project.

Discover existing README files before asking the owner to repeat their contents:

1. Find root files named `README` or `README.*`, case-insensitively (for example,
   `README.md`, `README.rst`, `README.txt`, or `readme.md`). A filename match
   identifies a candidate, not an approved contract. Do not execute file contents.
2. If multiple root candidates exist, list their paths and ask which is
   authoritative; do not silently prefer Markdown or merge their promises.
   If none exists, ask for the tool's purpose and offer to draft a root README.
   If only module READMEs exist, clarify the project scope rather than promoting
   one to the root contract automatically.
3. Read the selected root README. Find relevant module README candidates within
   the project using the same naming rule, guided by its module links and the
   requested stage. Skip version-control internals, dependency/vendor trees,
   generated/build output, and the installed skill's own files. Do not follow
   links outside the project without the owner's direction. Ask about competing
   module candidates rather than choosing silently.
4. Report the selected root/module paths, summarize their promises and a small
   useful first stage, and ask only questions whose answers affect that stage's
   scope, behavior, feasibility, or permissions. Separate existing behavior
   from intended promises; do not treat discovery as author approval.
5. Resolve material gaps and conflicts, then obtain approval of the proposed
   stage and any new or changed promises before preparing its implementation
   kit. Preserve existing README text unless edits are authorized. Already
   approved, unchanged contracts need no ritual reapproval.
6. Prepare and privately verify the kit as described below. Before launching
   the implementation loop, obtain separate explicit permission for model
   usage/spending and its automatic commits and attempt-owned discards. Stop
   if required permissions or runnable model commands are missing.

This is an agent-guided **discover → clarify → approve → build** workflow,
not an automatic README watcher or permission to code immediately on discovery.

Derive who uses the tool and what they get from the selected README where
possible. Confirm missing name, language, scope, and consequential constraints;
list open decisions. The inherited
spec-loop pattern works well for a standalone command-line core, deterministic
collection first, with a thin harness front end. Check suitability rather than
silently forcing that architecture onto a different approved tool. For any
unproven assumption, name the cheapest authorized experiment that could
invalidate it and put evidence before infrastructure.

Accept author-supplied root and module READMEs. Do not redraft them merely to
fit a template; clarify only material gaps and conflicts. When absent, draft
them for the author's review. Write as if describing the finished tool, but
label examples as promises, not observed results. Cover:

- Purpose, intended users, explicit non-goals, installation and prerequisites.
- A first useful example with expected output; promised commands, inputs,
  outputs, workflows, and stage limitations.
- Configuration, credentials and precedence where applicable.
- Where data is read, written, sent or retained; privacy boundaries and
  prohibited effects.
- Failures, recovery, and important constraints.

Use module READMEs where they clarify boundaries, not for every directory.
The root defines public behavior and how modules fit together. Each supplied
or drafted module README defines responsibilities, interfaces, dependencies,
data ownership, and failures. Walk representative workflows through them.
Resolve root/module and module/module conflicts with the author; the coder
must not choose a convenient interpretation.

For model features, prefer a deterministic core that still works without a
model, and a checked pipeline (one request, structured reply, no tools, pinned
model, versioned prompt). Stage 1 has no model call. For configuration, surface
the inherited safety defaults for approval rather than silently adding them:
flags > environment > project file > user file > defaults; role names rather
than model names in code; credentials only from environment or a command in
the user file; keys in files are errors; project files cannot set key commands
or base URLs; unknown keys are errors; `doctor` shows resolved values and
sources but never secrets. Record applicable choices in the READMEs.

## 2. Agree early and record decisions inline

Root and module READMEs are authoritative. Supporting specs clarify precision
(schemas, protocols, internal seams, exact messages) without contradicting or
expanding those promises. If clarification implies a new promise, seek inline
approval first. Do not fill unresolved questions with plausible defaults.

Maintain a concise **Decisions** section in the root README throughout design,
implementation, verification, and real use. Each entry states the decision,
rationale, and status: proposed, deferred, approved, or superseded. Do not
record who made it. For module-specific decisions, put details in the module
README and a summary/link in the root. Update affected contract prose too;
a decision log must not leave contradictory promises in place.

Present choices inline for the author's actual approval as early as practical,
before preparing affected work. Silence and model recommendations are not
approval. Never mark an entry approved before approval is given. Already
approved author-supplied contracts need no ritual reapproval unless changed.

Before every kit, distinguish explicitly:

- **Approved decisions:** constraints this kit must respect.
- **Deferred decisions:** future questions, with a resolution point (for
  example, before the persistence kit). No scheduled task may assume an answer.
- **Local implementation freedom:** choices the coder may make within this
  contract, such as private helpers or algorithms without promised effects.
- **New contract changes:** reasons to pause affected work and return to the
  author, never permission to improvise.

Resolve design-changing questions required by this kit before building it;
leave independent future-kit questions visibly deferred. Define scope,
boundaries, verification, and local freedoms before launch. Routine choices
inside those freedoms need not interrupt the implementation loop. The coder
reports newly discovered decisions in `PROGRESS.md`; you fold them into the
READMEs outside coder attempts and bring routine findings to the next gate.

If evidence requires changing approved promises or additional authority,
pause affected work for discussion and inline approval. The coder must record
the blocker and not implement a speculative answer. The unchanged runner has
no semantic contract-change detector or approval channel: progress notes are
not an automatic pause mechanism. The strong model must stop/withhold the
affected run through the available harness, not leave it retrying unresolved
design work. Update affected READMEs, supporting contracts, tasks and checks;
reverify the revised kit before resuming.

## 3. Slice a usable stage and prepare its kit

Choose a bounded usable step, not arbitrary infrastructure. The source pattern
uses roughly 15–40 small tasks; use only as many as the approved step needs.
Derive each task/check from the relevant approved root/module promises.
Map promises to acceptance checks, including executable examples, failures,
privacy, prohibited effects, and cross-module workflows. Anything not adequately
checkable remains a visible limitation or decision, not a verified claim.

Use the unchanged [kit format](references/kit-format.md), with this authority
mapping:

- The selected root README and approved module READMEs remain the user-facing
  authority, regardless of their filenames. Record their exact paths in the kit.
- `SPEC.md` is the required, protected, **subordinate supporting contract** for
  this stage. Identify the authoritative README paths/sections, approved stage
  scope, promise-to-test mapping, precise details, limitations, deferred
  decisions and local freedoms. It is binding on the coder only consistently
  with the READMEs. Contradictions block the kit; do not let it override them.
- Keep the format's `README.md` application/run instructions **in the owner's
  root README**, in a clearly separated kit-operation section. Do not replace
  the finished-tool README with a runner manual or present stage commands as
  finished-tool behavior. Include exact apply/run commands, selected model
  commands, prior-check instructions, commits, `.loop/` logs and `STOP` location.
  Longer operator notes may live in a protected linked file, but the root must
  still satisfy the unchanged format's README requirements. Obtain approval
  for additions to supplied READMEs; distinguish promised examples from evidence.
- Copy `scripts/loop.sh` unchanged from this skill into the kit. Keep
  `tasks.json`, `PROMPT.md`, `PROGRESS.md`, and `.gitignore` containing `.loop/`.

The runner automatically protects `SPEC.md`, not READMEs. Explicitly list
**every approved root and module README path** in `tasks.json`'s `protected`
patterns, including modules outside this stage. Inventory the paths and verify
that each matches a grep ERE after JSON decoding. For conventional names this
fragment protects root and nested READMEs, along with typical kit files:

```json
"protected": [
  "(^|/)README\\.md$",
  "^docs/runner\\.md$",
  "^docs/contracts/",
  "_test\\.go$",
  "^testdata/"
]
```

Add escaped, anchored patterns for any differently named approved README,
all supporting contracts, fixtures, complete files and harness guards. Do not
assume this example is an exhaustive list. Check the inventory again after
every refinement/overlay. Make `PROMPT.md` instruct the coder to read the
approved READMEs, `SPEC.md` and `PROGRESS.md`; prohibit editing **all** approved
READMEs and protected files; state local freedoms and the contract-change
blocker procedure. Keep progress notes writable. The source toy fixtures test
the inherited runner mechanics, not README authority.

The kit author owns the specification and the judge. The implementation agent
owns the implementation. Protect specifications, acceptance criteria, tests,
fixtures, golden outputs, and verification infrastructure—not production code
by default. Prefer black-box checks through public interfaces and observable
effects. Leave production data models, package boundaries, algorithms,
concurrency, OS-access code, and architecture to the coder unless the approved
application contract requires otherwise. Stubs must leave real implementation
work; exact names/signatures are required only for contractual public interfaces
or specifically justified verification seams, not every internal function.

For deterministic verification, prefer simulated environments or interception
at existing external boundaries. If dependency injection is necessary, establish
the smallest practical interface; keep protected infrastructure policy-free.
Simulation may model external responses, but must not implement application
selection, scheduling, retries, classification, or other production decisions.
Do not copy production code from the private reference into the starting kit
merely to facilitate testing. Keep structural checks only when they establish
an explicit contractual property (for example, isolation of side effects), not
the reference's package layout or internal types.

### Protected-surface review (required acceptance gate)

Before accepting, handing off, or committing a kit, complete the
[protected-surface review](references/protected-surface.md) in a protected
section of `SPEC.md`. Repeat for overlays and judge changes. Inventory actual
paths matched by protection patterns, including runner-added protection, and
interfaces imposed by tests even when their source files remain writable.
Document every protected production artifact/interface with its contract anchor,
necessity, smallest alternative considered, and what engineering work it supplies.
Record separately work already fulfilled by the kit, work remaining for the
coder, and every judge-imposed architectural constraint with its contractual
justification. Explicitly record "none" where appropriate; unexplained protection
or architecture blocks acceptance. Narrow overbroad patterns. A legitimate
contractual seam or existing approved public API can remain fixed; a convenient
reference design is not sufficient justification.

Review coverage independently: reducing protection must not weaken behavioral
checks. Preserve failing-stub and passing-reference evidence, challenge plausible
incorrect implementations and ambiguous promises, and record coverage gaps.
Reference success proves existence of a passing solution, not an unambiguous
specification or a sufficient judge. This is an author review gate, not a new
runner feature or automatic approval.

Tests are table-driven where useful, with informative failures, fixtures and
golden files nearby. Each ordered task has one explicit test command and a
nonempty `expect` list of full-line stdout EREs; `pass_marker` is rejected.
Use `normal` or `hard` tier. Put the formatted, checked, all-tests task last.
An overlay replaces the old whole-tree task rather than leaving it mid-list.

Verify external effects (models, environment, subprocesses, Git) through public
boundaries or minimal justified seams; no test needs network access or a key.
Use the standard library unless a dependency is approved. Overlay checks must
not assume earlier coder internals; leave file/package choices to the coder
unless the approved application contract constrains them. The inherited safe default is for
the built tool to write only under its own home, never dirty a user's project;
any necessary exception is a consequential contract decision for approval.

## 4. Verify every kit before handoff

Judging, not coding, dominates stage time: `--check` re-runs every earlier
task for each task, so its cost grows with the square of the task count. Use
the single-pass `--check-once` (same commands, timeouts, full-line
expectations, `format_check` and `check`, each run once) for every check on a
fixed tree, and the full `--check` once, at stage acceptance.

1. Write a private reference implementation and keep it in a durable location
   outside the kit (for example `<tool>-private-reference/<stage>`), never only
   in a temporary directory that a restart or cleanup can erase. Exclude it and
   its production scaffolding from the coder's kit. Complete the
   protected-surface review before kit acceptance or any separately
   authorized commit.
2. On supplied stubs, every new implementation task must fail. A passing stub
   means inadequate checks, a filter running no tests, or work already complete:
   fix the check (include a must-succeed case) or remove the task. For a
   corrective kit over an existing build, run only the new and changed tasks:
   `scripts/loop.sh --check-once ID...`. Earlier tasks are already evidenced.
3. On the reference, every task, `format_check` and `check` pass with
   `scripts/loop.sh --check-once`, the runner's own judge functions. On stubs
   the final whole-tree task must fail.
4. Stage acceptance: after the stage's last loop, run one full, unmodified
   `scripts/loop.sh --check` on the coder's build. Its repetition also exposes
   flaky or order-dependent tests. Corrective rounds before then use
   `--check-once`.
5. For overlays, apply to the previous build, compile and preserve every prior
   stage check. Report whether this was the owner's actual implementation or
   only the private reference. A sandbox result is not owner-build verification.
6. Exercise the built program by hand through its user-facing interface with
   representative fixtures, including promised examples where practical.
7. Report precisely what was and was not verified. Passing fixtures show a
   solution exists; they neither establish every user need nor exclude every
   wrong solution. Never call an outline, build, reference, or local fixture
   test a live integration or actual-use validation.

## 5. Run only the authorized bounded implementation loop

The unchanged runner requires Bash, Git, jq, and `timeout` or `gtimeout`, plus
the kit's language/check tools. Do not install prerequisites without permission.

- Start on a branch (not main/master/detached HEAD). The runner refuses tracked
  changes, non-ignored untracked files and index flags (`assume-unchanged` or
  `skip-worktree`), which hide edits from git; it lists them. Resolve outputs
  only with authorization; never hide or discard user work to pass the gate.
- Each attempt starts a fresh coder process; state lives in files and Git.
  Task selection tests once in order, chooses the first unfinished task and
  reuses its failing output in the prompt, together with discarded diff/notes.
- Normal first attempts use the cheap command, retries and hard tasks the
  strong command, last attempts the strongest, without fallback. Exact commands
  appear in `.loop/loop.log` and `Coder-Command:` commit trailers.
- Restore protected paths including new files, run `format`, restore protected
  paths again, record the tree, then judge `format_check`, this task, earlier
  tasks and `check`. Optional top-level commands are skipped only if absent.
  Protected matching uses NUL-delimited Git paths with rename detection off, so
  quoted (non-ASCII) or renamed names cannot escape restoration. If a coder breaks
  the `.loop/` ignore rule, `.gitignore` is restored from HEAD before snapshots.
  If `.loop/` is still not ignored after that (for example, because a rule in
  `.git/info/exclude` was removed), the run stops before judging or committing anything.
  Each task requires exit 0 and every `expect` matching a complete stdout line;
  stderr cannot satisfy it. Empty/missing expectations are task-named kit errors,
  as is any expectation containing a newline (each must be one full-line regex).
- An attempt that sets an index flag (`assume-unchanged`, `skip-worktree`, or
  both together) has the flag cleared, and the file restored if protected, before
  any path is read. Without this, git would hide the edit from restoration and
  from the commit. A flag set by the formatter or a judge command fails the
  attempt: the flag is cleared, and the discard restores protected files. Names
  are read NUL-delimited, so a file whose name contains a newline is refused at
  startup and cleared during an attempt like any other. A name containing a
  newline and then `h`, `s` or `S` and a space can be reported as flagged when it
  is not: the run is refused or the attempt fails, never passed.
- A run must start at the repository top level, not in a subdirectory; it is
  refused otherwise, before any state is created.
- Reject judge commands that change the tree. A pass commits exactly the judged
  tree with no intervening changes or rewriting commit hooks and asserts a
  clean checkout. A pass that leaves the tree unchanged is a failed attempt, not a
  commit. `git add -A` includes legitimate attempt-created new files.
  Ignored files are not part of that tree. Ignored files created by the attempt
  that match a protected pattern are removed before judging. Other ignored files
  created by the attempt are logged as not committed, but kept after a pass. Whether
  judging may depend on such files is an open owner decision (development
  review, deferred decision 14).
- A failure saves added `PROGRESS.md` lines to `.loop/notes.<task-id>`, then
  discards attempt-owned changes, including ignored files the attempt created,
  whatever their names (non-ASCII names included).
  Ignored files that existed before the attempt and `.loop/` are kept. Pre-existing
  ignored files that the attempt modified or deleted in place are not restored
  (development review, deferred decision 15).
  Notes from discarded attempts are included for subsequent tasks too, not
  committed; logs/diffs remain in `.loop/`.
- `--check` runs the same judge without a coder or formatter. Check commands
  must not mutate the accepted source tree. `--check-once [ID...]` runs
  `format_check`, the selected (default all) tasks and `check` once each,
  printing `pass`/`FAIL` lines; unknown ids are an error. It never commits or
  discards and does not replace `--check` for stage acceptance. Both check-only
  modes fail when judge commands change the working tree. Creating an untracked
  file counts as a change, and a working tree that cannot be snapshotted fails.
- Limits: `MAX_ITER=60`, `MAX_ATTEMPTS=4`, `ITER_SECONDS=1200`,
  `JUDGE_TIMEOUT=300`. Owner environment overrides must be positive integers;
  an empty value is refused, not defaulted, and owner commands must not be blank.
  A kit's `format`, `format_check` or `check`, if present, must not be blank;
  a blank command is a kit error, not a skipped or passing check.
  Every formatter, format check, task test (including diagnostic probes) and
  kit check is timed. Timeouts fail attempts, including a coder timeout whatever
  partial work it left, and log the command; a command
  that ignores SIGTERM is killed 5 seconds after its timeout. The runner
  stops at all tasks passing, a task's attempt limit (`STOP` names it), or the
  iteration cap; partial progress is not completion.

### Claude Code and Codex hosts

When working in Claude Code or Codex, do not use the runner's inherited Pi
defaults or require Pi installation. For Codex, obtain owner-selected,
non-interactive `codex exec` commands for all three command variables; check
stdin handling, model selection, sandbox permissions, and supported flags
with the installed CLI before launch. Do not bypass its sandbox or approval
controls. Authentication and a real attempt still need separate validation.

For Claude Code: Before launch, obtain owner-selected Claude commands
for **all three** of `CHEAP_CMD`, `STRONG_CMD`, and `STRONGEST_CMD`. They must
read the task prompt from stdin and run non-interactively (`claude --print`),
with suitable authorized tool permissions and the owner's chosen models.
Confirm supported flags with the installed CLI's `--help`; a help check does
not verify authentication, model availability, or implementation behavior.
Do not add permission-bypass flags to make a failing attempt pass. If tools
are denied, stop and resolve the required permissions with the owner. Do not
launch until commands and spending/commit/discard permissions are approved.
Record the exact commands in the kit-operation instructions. The runner stays
unchanged; environment overrides select the host's coder commands.

Inherited pinned script defaults (not a claim these models are available):

```bash
CHEAP_CMD='pi --provider anthropic --model claude-haiku-5-5 --thinking high --print --no-session'
STRONG_CMD='pi --provider openai-codex --model gpt-6.1-sol --thinking high --print --no-session'
STRONGEST_CMD='pi --provider openai-codex --model gpt-6.1-sol --thinking max --print --no-session'
```

Confirm exact commands with the owner before launch; record them in the kit's
operation instructions and result. Never silently substitute a model or change
`openai-codex` to `openai`. The owner can override through these environment
variables; a kit must not set them in `tasks.json`. Explicitly empty commands
refuse startup. Commands read stdin with `TASK_ID` and `ATTEMPT` in the
environment. Defaults are pinned, not dynamically selected from available models.

## 6. Review, use, and refine between kits

Order reviews to find problems before a coder round depends on them:

- Before handoff, have an independent reviewer read the approved contract,
  `SPEC.md`, tests and private reference (no coder code yet), concurrently with
  kit verification. Specification flaws found here cost one kit edit instead of
  a coder round, a judge run and a corrective kit.
- After the loop, review the coder's build while it is being judged. Reading
  code does not disturb timing-sensitive tests; serialize only work that does
  (judge runs, timing-sensitive integration scenarios).
- Batch every known finding into one corrective kit rather than one round per
  finding. Record each step's wall time and model spend in the stage record so
  slow steps are visible.

Review the implementation diff for fixture-specific shortcuts and tests passed
the wrong way. A stub's error can accidentally satisfy a check; a test-binary
`init` can exit 0 without running tests. Judge by observed passing tests as
well as exit status. Guard commands built from possibly empty file lists.

Return to the author with verified evidence, limitations and newly discovered
decisions. The owner uses the result on real work and reports concrete misfires
(wrong flags, awkward output, missed cases), not necessarily a large labeled
set unless a published accuracy claim is intended. Update READMEs, supporting
contracts and checks from those findings, not just to describe whatever the
code happened to do. Review the broader picture; if evidence invalidates it,
revise and approve it rather than preserving a mistake to stay unattended.
Approve the next layer inline, then prepare and reverify the next kit.

## Deliver each time

- Root/module README paths and decisions with status, plus supporting spec paths.
- Kit branch or zip/overlay, exact apply/check/run commands and owner-selected
  models; necessary permissions and prerequisites, without assuming permission.
- Completed protected-surface review in `SPEC.md`: justified production
  protection/interfaces, supplied and remaining engineering work, judge-imposed
  architectural constraints, alternatives, coverage challenges, and unresolved gaps.
- Stub/reference/judge/whole-stage/interface evidence and prior-stage results.
- What remains unproven: owner implementation, harness integration, live models,
  real use, security or other untested promises as applicable.
- Local freedoms, deferred future-kit questions and resolution points, blockers,
  and the next author-review gate. Do not choose the trial project for the owner.

## Local maintenance checks

After inspecting the scripts, run `bash scripts/test_loop.sh` for the inherited
fake-coder regression suite (68 cases and deliberate mutations). Optionally run
`bash tests/run.sh` for the inherited Go toy kit; it also requires Go and Perl.
Both use disposable fixture Git repositories only, never a real kit or model.
Keep these tests and the local runner self-contained. Compare runner and format
bytes with the recorded source before claiming unchanged reuse; the runner now
differs from spec-loop by `--check-once`, fixed-task metadata and expectation
caching, check-only tree-change detection, exact task-file protection,
NUL-delimited rename-free protected matching, `.loop/` ignore-rule restoration,
index-flag clearing (NUL-delimited, so newline names are included), removal of ignored files on discard, kill-after timeouts, a stop when `.loop/` is still unignored after restoration, top-level-only starts, and no-change passes treated as failed attempts. Installation,
startup discovery and a live workflow trial are separate checks, not implied by
these packaging tests.
