# readme-loop

Write the README first. Agree on what it promises. Then build the software that fulfills those promises.

readme-loop is a coding-agent skill for building tools from a user-facing contract. The owner supplies the README for the finished tool, or a strong model drafts it for the owner's approval, before implementation begins. The strong model turns that agreement into tests and bounded tasks, verifies that the assignment is achievable, and hands implementation to a coding model working in a test-judged loop.

The README describes the tool being built—not readme-loop itself. This document applies the same practice to readme-loop: it is the approved design contract. Local installation tests and a live Claude Code workflow are separate checks (see [Status](#status)).

## Installation

Install and authenticate your preferred coding agent: Claude Code, Pi, or Codex.
You also need Bash and Git. This public repository can be cloned without
GitHub authentication:

```bash
git clone https://github.com/Version2beta/readme-loop.git
cd readme-loop
```

Run **one** installer option for each agent you use:

| Agent | Install command | Installed directory | Invoke in the agent |
| --- | --- | --- | --- |
| Claude Code | `bash scripts/install.sh --claude` | `~/.claude/skills/readme-loop` | `/readme-loop` |
| Pi | `bash scripts/install.sh --pi` | `~/.pi/agent/skills/readme-loop` | `/skill:readme-loop` |
| Codex | `bash scripts/install.sh --codex` | `~/.agents/skills/readme-loop` | `$readme-loop` |

Codex's user skill location and explicit invocation are documented in its
[skills guide](https://developers.openai.com/codex/skills/). Pi uses its
personal skill directory; no Pi package or npm publication is required.

The installer copies the skill and supporting files to the selected directory.
It does not install dependencies, call models,
modify Claude settings, or start a build. It refuses existing installations,
including symlinks, rather than overwriting your changes. Keep the clone for
updates; updating an installed copy is manual for now.

## Quickstart

Start a fresh agent session **in the project you want to build**, not this
skill's checkout. Use your agent's invocation from the table above, followed
by this request (shown for Claude Code):

```text
/readme-loop Read my existing README files, summarize a small first stage, and ask about gaps. Don't launch the implementation loop yet.
```

In Pi, replace `/readme-loop` with `/skill:readme-loop`; in Codex, replace it
with `$readme-loop`. These are agent prompts, not shell commands.

Expected first interaction: the agent discovers `README`/`README.*`, asks which
is authoritative if necessary, summarizes the selected contract, and clarifies
material gaps. If no README exists, it asks what you want to build and offers
to draft one. You approve the stage before kit preparation. This is the intended
experience; live agent discovery and end-to-end workflow trials have not yet
been performed.

### Before running an implementation loop

The runner also needs Git, jq, `timeout` (or `gtimeout` on macOS), and the tools
required by your project. On macOS, Homebrew's `coreutils` supplies `gtimeout`.
The first design conversation does not require these runner dependencies.

The inherited runner defaults invoke Pi, but its model identifiers are not a
claim of availability. Confirm all three commands before any launch.
**Claude Code and Codex users must override all three coder commands**
(`CHEAP_CMD`, `STRONG_CMD`, `STRONGEST_CMD`) with commands for their chosen CLI.
The skill asks for your models, commands, tool permissions, and spending limits;
it must not silently switch hosts or bypass permission checks. Launching the
skill in one agent does not automatically configure the implementation runner.
Unattended execution with Claude Code or Codex remains unverified. The runner commits
passing attempts and discards attempt-owned failed changes, so both actions
need your explicit permission. Use an isolated, clean project checkout.

### Remove or troubleshoot

If the skill is missing, check for `SKILL.md` in your agent's installed directory
from the table and restart the agent. In Codex, `/skills` also lists available
skills. To disable it, move its `readme-loop` directory outside the agent's
skill directory; to uninstall, delete only that installed copy after preserving
local changes. Installing a new copy requires moving the existing installation
out of the way first.

## Local checks and CI

```bash
python3 tests/test_install.py
python3 tests/test_kit_format.py
bash scripts/test_loop.sh
bash tests/run.sh
```

Installer tests use temporary home directories. Runner tests use fake coders
and disposable Git repositories, not real models; the toy suite also requires
Go and Perl. CI defines Linux/macOS checks and an installable `readme-loop.tar.gz`
artifact containing only the skill, README, references, scripts, and tests.
No npm publication or release is configured. Downloading CI artifacts through
GitHub requires signing in. CI execution is not implied by adding its workflow file.

## Why start with a README?

A README forces you to explain the software to someone who wants to use it. Who is it for? What problem does it solve? What commands do they run? What happens when something goes wrong?

Those questions expose decisions before they become implementation details. The document is short enough to review, concrete enough to challenge, and useful after the code exists.

The aim is not to squeeze an entire engineering specification into a README. It is to make the public promises clear, then derive the supporting contracts and checks without quietly inventing more behavior.

## What you get

For each stage, readme-loop produces:

- An owner-approved root README describing the usable result, with module READMEs where useful.
- Supporting contracts for details that need more precision than the README should carry.
- Tests, fixtures, protected files, implementation stubs, and an ordered task list.
- A private reference implementation used to verify the kit, excluded from the implementation handoff.
- A bounded implementation loop that judges attempts by checks rather than the coder's claims.
- A report of what was verified, what remains unproven, and what decisions still need the owner.

Each stage ends with something the owner can use. Real use informs the next revision of the README and the next stage.

## Progressive refinement

Refine the whole design before filling in every detail of an individual module. Like a progressive JPEG, establish the recognizable picture first, then increase its resolution. The aim is to discover expensive decisions early and keep late decisions cheap—not to pretend that every refinement will be additive.

Use two nested loops:

- **Design loop:** refine the root and module READMEs with the author, approve decisions inline, and prepare a bounded implementation kit.
- **Implementation loop:** execute that verified kit unattended within its approved contract, then return the results to the design loop.

Progress through these levels as useful; they are review gates, not a requirement to produce four separate kits:

| Level | Establish | Review gate |
| --- | --- | --- |
| Outline | Users, useful workflows, examples, non-goals, and important constraints. Leave algorithms and file organization open unless they determine feasibility. | Does the author want the tool described here? |
| Structure | Module responsibilities, interfaces, data ownership, external effects, and failure behavior. Walk representative workflows across module boundaries. | Are the boundaries coherent and consequential choices approved? |
| Skeleton | A thin end-to-end implementation through real interfaces for a small useful case, with explicit limitations. Test risky assumptions first; use a disposable experiment earlier when needed. | Does executable evidence support the design, or must the READMEs change? |
| Detail | Additional workflows, edge cases, integrations, and necessary performance work in successive usable steps. | Does the added detail preserve the approved contract? |

Order decisions by how much later work they constrain and how costly they would be to reverse, not merely by whether they sound like design or implementation. A persisted storage format belongs early if users will retain data in it. A sorting algorithm can usually wait unless its performance determines feasibility.

For each upcoming kit, distinguish:

- **Approved decisions:** constraints the kit must respect.
- **Deliberately deferred decisions:** open questions with a stated resolution point. Do not schedule work that depends on an assumed answer.
- **Local implementation freedom:** choices the coder may make within the approved contract without interrupting the loop.
- **Newly discovered contract changes:** reasons to pause affected work and return to the author, not permission to improvise.

Define each kit's scope, boundaries, verification, and local implementation freedom before launch. Every implementation kit, including a skeleton kit, receives the same failing-stub, passing-reference, and judge verification described below. Approval of an outline does not establish feasibility, and a passing skeleton does not establish the complete tool.

Between kits, review the evidence and approve the next layer of detail. If evidence invalidates the broader design, revise the READMEs and affected checks and reverify the kit before continuing. Do not preserve a mistaken picture merely to keep the loop unattended.

## How it works

### Start with an existing README

Invoke the skill from the project you want to build, or give it that project's
path. It discovers root `README` and `README.*` files case-insensitively, reads
the selected contract, and finds relevant module READMEs. It skips dependency,
generated, and version-control trees. If multiple root candidates exist, it
asks which is authoritative rather than silently choosing one. If none exists,
it asks about the tool and offers to draft a README for approval.

The first response identifies the README paths, summarizes the promises and a
small useful first stage, and asks about material gaps or conflicts—not things
the README already answers. Discovery alone does not make a document approved.
After clarification, you approve the stage and any new or changed promises
before the agent prepares and privately verifies the implementation kit.
Launching the build loop needs separate permission for model usage/spending,
automatic commits, and discarding attempt-owned failed changes.

In short: **discover → clarify → approve → build**. This is skill guidance for
the coding agent, not a background watcher or a standalone README parser.
Live discovery and workflow behavior remain unverified.

### 1. Describe the finished tool

Start with one sentence: who uses the tool and what they get.

Then write its README as if the tool were ready to use. Include:

- Purpose, intended users, and explicit non-goals.
- Installation and prerequisites.
- A first useful example, including expected output.
- The commands, inputs, outputs, and workflows the stage promises.
- Configuration, credentials, and precedence where applicable.
- Where data is read, written, sent, or retained.
- Expected failures, limitations, and recovery steps.

Examples describe promised behavior; they must not be presented as observed results before implementation and verification. Unresolved decisions stay visibly unresolved rather than being filled with plausible defaults.

### 2. Agree on the promises

The owner may supply the README or have the strong model draft it for review and approval. Author-provided documents need clarification only where material ambiguities remain. The strong model identifies ambiguities, conflicting promises, and assumptions that could change the design.

For complex projects, especially those with multiple modules, use module READMEs where they make boundaries easier to understand—not automatically for every directory:

- The root README defines the project's purpose, user-facing behavior, and how its modules fit together.
- Module READMEs define each module's responsibilities, interfaces, dependencies, and failure behavior.
- Each module README may be supplied by the owner or drafted by the strong model and approved by the owner.
- Module contracts must agree with the root contract and with one another. Conflicts go back to the owner for resolution; the coder must not silently choose an interpretation.

Resolve design-changing questions needed for the upcoming kit before preparing it. Future decisions may remain explicitly deferred when the kit does not depend on their answers. When feasibility is uncertain, run the smallest authorized experiment that could disprove the idea before building infrastructure around it.

Keep the README focused on the user's experience. Put precise schemas, protocol details, and internal interfaces in supporting documents when necessary. Those documents may clarify the README; they may not silently contradict it or expand its promises.

#### Record decisions as the work proceeds

Decisions made throughout design, implementation, verification, and real use must be added to the project's root README. Keep a concise Decisions section stating the decision, its rationale, and its status (proposed, deferred, approved, or superseded), without recording who made it. For module-specific decisions, record the details in the module README and include a summary and link in the root README.

Present decisions inline in the README for the author's approval as the project is built. Record approval only after the author actually gives it; silence or an agent's recommendation is not approval. Surface design choices and obtain approval as early as practical, before preparing the affected kit, so its implementation loop can run unattended within the agreed contract. Routine implementation choices within that contract need not interrupt the loop; bring newly recorded decisions to the author at the next review gate.

The strong model maintains this record outside coder attempts. The coder reports newly discovered decisions through the loop's progress notes rather than editing protected READMEs. If a decision changes approved promises or requires additional authority, pause the affected work for discussion and inline approval. Update the affected contract text and checks, reverify the kit, and only then resume.

Multiple kits for successive usable steps are expected when useful. Between kits, take an intermission to review results with the author, discuss design decisions, and approve the README updates before preparing the next kit. Do not force every future decision up front, or let the loop silently settle unresolved design questions merely to stay unattended.

### 3. Turn promises into checks

Choose a usable stage. Derive tests and implementation tasks from the relevant approved root and module READMEs. Include checks at module boundaries where the promises depend on modules working together. For each promised behavior, identify how to verify it. Executable examples become acceptance checks where practical. Failures, privacy boundaries, and prohibited effects need checks too—not just the successful path.

The kit author owns the specification and the judge. The implementation agent owns the implementation.

The strong model prepares the stage's tests, fixtures, minimal interfaces and stubs, protected verification files, and ordered tasks. Each task has a bounded implementation scope and an explicit test command with expected passing output. Prefer black-box verification through public interfaces and observable effects. Production data models, package boundaries, algorithms, concurrency, OS access, and architecture remain the implementation agent's responsibility unless the approved application contract requires otherwise.

#### Protected-surface review

Before a kit is accepted, handed off, or committed (with separate authorization), complete the [review template](references/protected-surface.md) in a protected section of its `SPEC.md`. Repeat for overlays and judge changes. Document:

- Every protected production artifact or fixed interface, why it is necessary, its contract or verification justification, and the smallest alternative considered.
- Engineering responsibilities already fulfilled by the kit and those remaining for the implementation agent.
- Architectural constraints imposed by the judge, including internal imports and structural tests, with their contractual justification.

Protect specifications, acceptance criteria, tests, fixtures, golden outputs, and verification infrastructure. Use the smallest practical deterministic simulation, interception, or injection interface; keep protected infrastructure free of application policy. A protected fake may simulate an OS response, but must not supply the application's qualification, retry, or scheduling decisions. Do not copy production code from the private reference into the starting implementation merely to facilitate testing. Structural checks may establish explicit properties such as side-effect isolation, not incidental reference architecture.

Unjustified production protection or architecture blocks kit acceptance. Review actual protection-pattern matches, including future production paths; a complete-file label is not justification. Narrow the protected surface without weakening behavioral checks. The review is an authoring discipline, not additional runner enforcement.

A promise that cannot be adequately checked is a visible limitation or a decision to resolve, not something to label verified.

### 4. Verify the assignment

Before handing the kit to the coder, the strong model writes a private reference implementation.

- Every implementation task must fail on the supplied stubs.
- Every task must pass with the reference implementation under the same judge used by the loop.
- The reference lives in a durable location outside the kit, never only in a temporary directory.
- The whole-stage checks must pass.
- The built tool must be exercised through its user-facing interface using representative fixtures.
- Later stages must preserve the earlier stage's checks; report whether this was verified against the owner's actual implementation or only the reference build.

Judging is the slow part of a stage: the runner's full `--check` re-runs every earlier task for each task, so its cost grows with the square of the task count. Verification of a fixed tree therefore uses `scripts/loop.sh --check-once`, which runs the same commands and expectations once each; a corrective kit's must-fail check runs only its new tasks. One full `--check` on the coder's build remains the stage's acceptance gate. Reviews of the specification and reference run before the coder loop, alongside verification, so specification flaws do not cost a coder round.

The reference implementation is not part of the coder's kit. It establishes that a passing implementation exists and helps expose defective assignments. It does not prove that the specification is unambiguous, that the README captures every user need, or that the judge excludes every incorrect implementation. Review ambiguities and challenge plausible incorrect behavior independently; record residual coverage gaps.

### 5. Implement in a bounded loop

The runner selects the first unfinished task and starts a fresh coder process. State lives in files and version control, not in a long conversation.

The coder implements the task but cannot change any approved root or module README, supporting contracts, tests, fixtures, task definitions, runner, or other protected files. It cannot mark its own work complete.

After an attempt, the runner restores protected files, formats the implementation, and checks the task, earlier tasks, and stage-wide requirements. Passing requires both a successful command exit and the expected passing test output. Checks must not mutate the accepted tree.

A passing attempt may be committed only with the owner's explicit authorization. A failed attempt may have its attempt-owned changes discarded only with explicit authorization. Pre-existing user work must always be preserved. Without the required permissions, the loop must stop rather than improvise.

Retries, model escalation, execution time, and iteration counts are bounded. Model commands are owner-selected and recorded. The loop stops when all tasks pass or a limit is reached, and reports the result without treating partial progress as completion.

### 6. Use the result and revise the contract

The owner uses the tool on real work and reports misfires: an awkward command, surprising output, a missing case, or an incorrect result.

Review the implementation for ways it may have satisfied the fixtures without fulfilling the broader promise. Feed those findings into the README, supporting contracts, and tests for the next stage. Do not let the documentation become a description of whatever the code happened to do.

## Roles

| Role | Responsibility |
| --- | --- |
| Owner | Decides purpose, scope, public behavior, spending, models, and consequential actions; reviews the README and uses the result. |
| Strong model | Helps write the README; resolves ambiguities with the owner; prepares and verifies the kit; reviews results. |
| Coding model | Implements one bounded task from the supplied files without changing the contract or its checks. |
| Runner | Selects tasks, enforces protected paths and limits, judges attempts, and performs only authorized commit or discard operations. |

## Relationship to spec-loop

readme-loop retains spec-loop's verified kits, private reference implementation, protected contracts, bounded tasks, and test-judged implementation loop.

The difference is where the contract begins. spec-loop begins with a dedicated specification. readme-loop begins with the document a user would read to understand and use the finished tool. Supporting specifications follow when needed, but the user-facing promises remain authoritative.

This is not simply a filename change. A README that says only “a fast, easy-to-use tool” is not an implementation contract. It needs concrete workflows, examples, boundaries, and failure behavior before the loop can safely begin.

## Permissions and limits

Writing or reviewing a README does not authorize paid model calls, running an implementation loop, commits, discards, remote changes, or production access. Obtain explicit permission for consequential actions and preserve existing work.

Protected files and Git checks constrain accepted changes; they are not a security sandbox. An unattended coder may execute commands with the permissions available to its process. Use isolation and provider spending limits appropriate to the workload.

Tests provide evidence about the cases they exercise. They do not replace owner judgment, integration checks, security review where warranted, or actual use. Reports must distinguish source inspection, build success, tested behavior, live integrations, and unresolved uncertainty.

## Decisions

| Decision | Rationale | Status |
| --- | --- | --- |
| Define `/readme-loop` in this project's root `SKILL.md`; this directory is the self-contained skill. Pi's explicit invocation is `/skill:readme-loop`, not a new slash-command extension. | Keep the first interface a portable skill rather than another executable integration. | Approved |
| Support Claude Code, Pi, and Codex via a local copy installer after a GitHub clone; test and archive the skill in CI without npm publication. | Give users a short install path without requiring a different agent or a custom download service. | Approved |
| Make the repository public and use an unauthenticated Git clone in installation instructions. | Remove private-repository access setup from the installation path. | Approved |
| Reuse spec-loop's runner with unchanged attempt judging and kit schema, adapting authoring guidance for minimal production protection. | Keep verified execution mechanics while assigning production engineering to the implementation agent. | Approved |
| Add a read-only `--check-once` to the runner; verify kits with single-pass checks and run the quadratic full `--check` once at stage acceptance; review spec and reference before the coder loop; keep references durable. | Measured on drift Stage 5a, judging took about 2 of roughly 3 hours per correction round and repeated identical deterministic tests. | Approved |
| Require a protected-surface review before kit acceptance, handoff, or any separately authorized commit. | Preserve independent verification without silently prescribing production architecture. | Approved |
| Root and module READMEs are authoritative; supporting specifications clarify them without contradiction or new promises. | Keep user-facing agreements in control while allowing precise implementation contracts. | Approved |
| Discover existing `README`/`README.*` files, clarify ambiguity and material gaps, obtain stage/contract approval, then prepare a verified kit; require separate launch permissions. | Build from the owner's existing documents without silently choosing authority or starting implementation on discovery. | Approved |
| Use progressive refinement and author-review intermissions between kits, not a separate automated design runner. | Surface consequential decisions early, use implementation evidence to refine the design, and leave independent future-kit decisions open. | Approved |

## Status

First local skill packaged in [SKILL.md](SKILL.md), with spec-loop's
[runner](scripts/loop.sh) (plus `--check-once`), adapted [kit format](references/kit-format.md), and their
self-contained regression scripts/fixtures. This is packaging and local test
evidence, not an installed or live-trialed workflow.

The unchanged format still requires `SPEC.md`. The skill maps it to a
subordinate supporting contract derived from the approved READMEs. Every kit
must explicitly protect all approved root/module README paths in `tasks.json`;
the runner does not protect READMEs automatically. The owner's root README
retains its finished-tool contract and adds a clearly separated kit-operation
section with the apply/run instructions required by the format, rather than
being replaced by a runner manual.

### Pi discovery and invocation (not performed)

This directory contains the complete skill. After separately authorized setup,
place or symlink it in a Pi skill location (for example,
`~/.pi/agent/skills/readme-loop`), or include this directory in Pi's `skills`
settings. Reload and inspect discovery diagnostics, then invoke
`/skill:readme-loop` with the request. `/readme-loop` is the workflow name;
no custom command alias is installed by these files. Loading the skill does
not authorize model calls or an implementation run.

### Installer validation

Current local checks passed:

- Six installer tests: complete Claude copy, Pi/Codex destinations, overwrite
  preservation, symlink refusal, help/invalid arguments, and missing-package
  refusal. Tests used temporary home directories, not real agent settings.
- A locally created distribution archive was extracted and passed the same
  six tests; private working data and the article are excluded.
- Shell syntax checks passed for all five scripts.
- All 26 runner cases and 26 deliberate regression detections passed again;
  all 11 Go toy-kit assertions passed with isolated Git configuration,
  temporary Go caches, and downloads disabled.
- At the installer-validation revision, runner and kit-format hashes matched
  the original values below. The kit-format guidance has since changed.

The Linux/macOS CI workflow is added but has not run on GitHub. These checks
prove file installation and fixture behavior, not live agent discovery,
authentication, model availability, or a real build. No installed user skills
were changed and no real model calls were made.

### Protected-surface methodology validation

Local checks on this methodology update passed: two tests exercise the published
kit example's EREs using grep, protecting contracts/verification while leaving
production packages and progress notes writable. All six installer tests, 26
runner cases with 26 deliberate regressions, and 11 toy-kit assertions passed.
Shell syntax and `git diff --check` passed. The runner's hash is unchanged.
CI now runs the example tests in source and extracted archives, but has not
run for these uncommitted changes.

The toy kit is a runner fixture with deliberately fixed function interfaces,
not a complete example of an accepted README-derived application kit. Its unit
tests and private toy reference remain useful regression evidence; they neither
justify an application's architecture nor validate the review's engineering
judgments. No drift files or installed skills were changed. No live models ran.

### Verification-cost update

`scripts/loop.sh --check-once [ID...]` runs `format_check`, the selected tasks
and `check` once each, reusing the judge's functions; attempt judging and
`--check` are unchanged. Three new runner cases (single run per task, task
selection and unknown ids, format and kit checks) each catch a deliberate
regression; all 29 runner cases and 29 regressions pass. The toy kit checks
that stubs fail and the reference passes `--check-once`. The skill's
verification procedure, review order and durable-reference rule were updated
to match. The drift time savings are an estimate, not yet measured on a stage.

### Original packaging validation and provenance

Copied from `/Users/rob/Development/skills/spec-loop` (the same directory linked
at `/Users/rob/.pi/agent/skills/spec-loop`). At initial packaging, the runner,
format, regression scripts, and toy fixtures compared byte-for-byte with that source snapshot. The runner has since added only `--check-once`;
the format's authoring guidance now includes the protected-surface review.
The source's `spec-loop` names and `SPEC.md` format are deliberately retained.
SHA-256:

- `scripts/loop.sh`: `4ed33daa824bd8ed999c141cf4abd55921981f5e8de86948408552b52dbb207f`
- Original `references/kit-format.md` (before methodology updates): `972367a9a45222b3070518ea3f632a2c974c2869aa0d39ba775dcf061a7de199`

Checks run from this directory:

- `bash scripts/test_loop.sh`: all 26 fake-coder cases passed; all 26 deliberate regressions caught.
- `bash tests/run.sh`: all 11 toy-kit assertions passed, including failing stubs, passing reference, rejected cheats, attempt limits, and dirty-tree refusal. Run with isolated Git configuration and temporary Go caches, with network/toolchain downloads disabled.
- `bash -n` on all four shell scripts: passed.
- Pi 1.5.2's local skill parser loaded exactly `readme-loop` with zero diagnostics; no Pi session, installation, or startup/discovery trial was run.
- Seven local Markdown links/anchors and seven JSON examples, balanced code fences, README protection patterns (root/nested READMEs protected, progress/code writable), and document/runner consistency checks: passed.
- Source byte comparisons and hashes: passed. `ARTICLE-DRAFT.md` remains unchanged.

Both regression suites create and remove only disposable fixture Git
repositories and use scripted fake coders, not real models or real kits.
Prerequisites are Bash, Git, jq, and `timeout` or `gtimeout`; the toy suite also
uses Go and Perl. No dependencies were installed.

Still open / not performed:

- [ ] Real user installation and startup/discovery verification in Claude Code, Pi, and Codex.
- [ ] Choice of the first small tool or stage for a workflow trial (deferred until before that trial).
- [ ] A real README-derived kit, private-reference verification, and authorized live implementation trial with owner-selected model commands and spending/commit/discard permissions.
- [ ] Real-use feedback and subsequent refinement; the article draft is not finished by this packaging step.

## Background

Tom Preston-Werner described [Readme Driven Development](https://tom.preston-werner.com/2010/08/23/readme-driven-development.html) in 2010. Earlier related practices include Fred Brooks's treatment of the user manual as an external specification in *The Mythical Man-Month* (1975).

A related implementation practice appears in BSD's history: Kirk McKusick describes Keith Bostic recruiting volunteers to rewrite Unix utilities from scratch using their published descriptions. See [“Twenty Years of Berkeley Unix”](https://www.oreilly.com/openbook/opensources/book/kirkmck.html), particularly “Networking, Release 2.” These are related ideas, not claims that the earlier authors used the term readme-loop.
