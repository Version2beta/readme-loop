---
name: readme-loop
description: Complete the agreed README scope in one invocation, with independently owned behavioral acceptance. Use for README discovery, clarification, implementation, evaluation and bounded corrective work. References and elaborate kits are optional, not prerequisites.
license: MIT
metadata:
  version: "0.2.0"
---

# readme-loop

Agree through the README. Implement freely. Accept through behavioral evidence.
Optimize total engineering cost and time to a useful, adequately correct result,
not coder cost, artifact count or verification volume in isolation.

This is an independent workflow, not a front end to another specification loop.
The default is **README → acceptance → implementation → evaluation → delivery**
for the entire agreed scope in one invocation. Internal milestones organize work;
they are not automatic approval gates or permission to stop at a partial product.
Narrow the deliverable only when the owner explicitly requests or approves that
narrower scope. Progress reports do not transfer responsibility back to the owner.
No dedicated specification, private reference implementation, task manifest,
stubs, copied runner or new agent is required merely to use this skill.

Resolve bundled paths from this skill's directory. Work in the owner's supplied
project, or the current directory if unambiguous—not in the installed skill.
Installation and invocation are described in [README.md](README.md).

## Authority and boundaries

- Inspect applicable guidance and relevant Git state; preserve existing work.
- A README is a candidate contract, not automatic approval. Obtain actual approval
  of the requested scope and changed promises. Honor existing approvals without asking
  again; never label recommendations or silence as approval.
- Work within authorized local actions. Paid model calls, additional agents,
  commits, discards, installation, remote changes and production actions require
  applicable explicit authorization. Before paid work, establish the authorized
  model routes, billing source, applicable spending control and stop conditions.
  Carry forward applicable answers already given, including owner-confirmed
  external caps. Do not ask again or require a duplicate local cap. External
  enforcement does not itself authorize a new route or paid calls.
- Do not install dependencies, bypass permissions or silently change models.
  A timeout or prompt instruction is not a monetary spending limit.
- Protect accepted requirements and evaluation from implementation changes.
  File protection is not a security sandbox. Use an appropriately isolated
  workspace and externally controlled evaluation when the risk requires it.
- New behavior, data access, destructive effects or other authority outside the
  agreed scope block affected work. Defer it and continue independent work only
  within the owner's permission; do not keep retrying an unresolved decision.

## 1. Read, clarify and agree

Discover root `README` and `README.*` files case-insensitively. If several could
be authoritative, ask which to use; if none exists, offer to draft one. Read
relevant module READMEs, following project links rather than scanning dependency,
archive, generated or version-control trees. Do not follow links outside the
project without direction. Identify the selected paths in the first response.

Separate intended promises from current behavior and old implementation defects.
Ask only questions that change the requested scope's observable behavior,
compatibility, ownership, important failure semantics, feasibility or authority.
Do not expand a small assignment into the ideal finished product, or shrink a
whole-product request to the first convenient transport, feature or checkpoint.

State the full agreed scope, acceptance, explicitly deferred features and local
implementation freedom. Private packages, algorithms and internal types belong
to the implementer; contractual APIs and observable effects do not. Resolve only
consequential contract gaps, not routine implementation choices. Once authorized,
continue through implementation, evaluation and correction without asking the
owner to approve each internal milestone.

Keep material decisions and their rationale/status (proposed, approved, deferred,
superseded) concise in the README. Update the actual promises too. Use module
READMEs or supporting schemas only where they resolve real ambiguity. Do not
require an audit history of every implementation choice or a duplicate SPEC.

### Incremental development

A README is a living contract. Subsequent invocations may extend, revise,
clarify, or remove previously agreed requirements.

When working on an existing project:

- Establish the previous accepted contract, current intended contract,
  implementation state, and available acceptance evidence.
- Use Git history, existing tests, previous delivery records, and current
  source as evidence where available. Do not require a separate specification,
  manifest, or requirements database.
- Identify behavioral changes rather than treating every textual change as a
  new requirement.
- Distinguish added, modified, removed, clarified, unchanged, and previously
  unfulfilled requirements.
- Reuse established decisions, implementation, acceptance checks, and evidence
  wherever they remain applicable.
- Identify dependencies and affected guarantees, including interactions with
  unchanged functionality.
- Establish independent acceptance for new or changed behavior before
  implementing it.
- Preserve unchanged acceptance obligations. When an approved requirement
  supersedes an earlier one, update the affected acceptance checks through the
  acceptance owner.
- Do not assume removing a promise from the README necessarily authorizes
  removing working functionality, breaking compatibility, or deleting data.
- Make the smallest complete implementation change that satisfies the agreed
  contract. Avoid unrelated refactoring.
- Run focused verification of changed behavior and regression checks
  appropriate to the affected guarantees.

The current README defines the intended product. Previous acceptance evidence
establishes what was demonstrated about an earlier candidate, not what is
necessarily true of the current candidate.

Complete the entire agreed increment in one invocation. Clearly distinguish
newly verified behavior, previously established evidence, outstanding
requirements, and any regressions.

Do not rebuild the product, recreate its acceptance suite, or repeat
preparation merely because the README has changed. Scale the effort to the
semantic change and its consequences.

### Required preflight: make the whole run executable

Before implementation, walk every required acceptance check, including final
integration, safety/failure cases and recovery. For each, identify what must run,
what evidence would count, and what it needs: the exact host or environment,
fixtures and services, toolchains and isolation, permitted data and model
routes, and any approvals or time windows. Inspect what is actually available;
an installed tool is not a provisioned environment, and a compile or simulated
pass does not supply missing runtime evidence. Reuse established facts and do
ordinary local discovery without asking. Keep this proportional: a few lines in
the initial plan can be enough; no separate document is required.

If anything essential is missing, **ask before starting the affected work**.
Batch all known consequential gaps in one message. For each, say exactly what
you propose to do or what the owner must provide, where and with what effects,
and which acceptance check it unlocks. Recommend the smallest suitable option
rather than asking the owner to design the environment. Distinguish your own
implementation or setup work from an owner decision, execution permission, or
resource only the owner can provide. A grant exercised inside the product under
test is not permission to install, spend, access a host, or reboot it.

If a gap remains open, say what is blocked and continue independent work within
existing authority. If a new blocker appears, raise it promptly with a concrete
request; do not save it for handoff. Do not quietly drop a required check or
replace it with a weaker one. This preflight is not a new approval gate for
routine work or a reason to ask again at each milestone.

## 2. Establish behavioral acceptance

The acceptance owner defines success; the implementer supplies the solution.
Before coding, map the important README promises to executable checks or other
explicit evidence. Use an existing test target or a short section in an existing
record—not a mandatory new document or manifest. Include successful behavior,
consequential failures, prohibited effects and relevant cross-boundary behavior.
Keep public examples executable where practical.

Prefer public interfaces and observable effects. Do not freeze production
architecture merely to match a reference. Use the smallest external fixture or
simulation needed, without supplying production policy as test scaffolding.
Existing implementations can inform differential checks, but are not authorities
for new promises and may contain defects.

Check collection and representative wrong behavior: an empty run, skipped test,
setup/compilation failure or plausible stub must not establish success. Record
what rejects meaningful incorrect behavior; a generic exit-0 command alone does
not establish that behavioral tests ran. Qualify only to the depth the risk needs.
A second complete implementation is not the default test-qualification method.

The implementer may add development tests, but must not change accepted checks,
fixtures or promises to make its implementation pass. Evidence requiring an
acceptance correction returns to its owner; preserve the finding and re-evaluate
without silently changing the meaning of success.

## 3. Complete the agreed scope

Use the host's ordinary coding tools and project-native build/test commands.
Keep useful implementation context across edits; do not launch a fresh model
for each small function or test. The implementer may maintain a private task
breakdown without imposing a microtask protocol on the project.

Run focused checks while editing. After a meaningful change, run the appropriate
regression checks; at final acceptance, run all required checks on the actual
candidate. Do not repeat earlier task checks quadratically. Repetition must
answer a specific question about ordering, timing, concurrency or instability.

Prefer inexpensive models where effective, but compare total cost and time.
Escalate only within approved model/budget limits when evidence makes that cheaper
than continued retries. No fallback model is selected silently.

Native checks are the default; no bundled runner is required. If useful,
`python3 <skill-dir>/scripts/check.py --cwd <project> --timeout 300 -- 'command' ...`
runs trusted commands serially, at most once each, stopping at first failure.
Read its help before use. It does not call models, format, commit, discard,
protect files, verify test collection or assert source immutability. It is not
a sandbox or an autonomous implementation controller.

## 4. Evaluate, review and correct within a limit

Use the accepted evaluation, not the implementer's completion message. Identify
the candidate revision or dirty state, exact commands, outcomes and relevant
artifacts. Checks must not silently modify accepted source; use disposable
snapshots/external fixtures where required and inspect relevant final state.
Run representative user-facing behavior, not just compilation. Judge only what
was actually exercised; simulation and source review are not live integration.

At the agreed completion boundary, seek one bounded independent review when authorized,
focusing on requirements, consequential failures and acceptance gaps. Independent
review needs a separate execution context; self-review is not independent, and
same-model correlation remains a limitation. Do not launch reviewers without
permission or claim review/approval on someone's behalf.

Batch findings into one correction pass and recheck the affected guarantees plus
necessary regression coverage. Further broad review requires a material reason,
not merely another minor finding. A serious unresolved defect blocks acceptance;
a review/correction limit is not permission to ship it. Record low-impact or
unrelated improvements without extending the assignment indefinitely.

Finish only when the entire agreed scope meets its acceptance/review boundary.
Stop early only at an explicit owner-requested partial-delivery boundary, an
execution/time/spend/retry limit, or a consequential decision/authority gap that
blocks safe progress. Report such work as partial or blocked, never complete.
Do not stop merely because an internal milestone passed. Use host-supported
continuation within existing authority when context needs refreshing; do not
invent a new approval gate. Do not spend merely because budget remains.

## 5. Deliver evidence and economics, not ceremony

Use one concise handoff in an existing record or response:

- Outcome and source state; selected README paths and scope.
- Commands/results and user-facing evidence; important gaps and remaining risks.
- Measured elapsed time and actual reported model cost for preparation,
  implementation, evaluation/review and correction where available. Separate idle
  waits and operator effort; unavailable values are unknown, never zero. Label
  estimates, billing reservations and reported costs separately.
- Deferred decisions, permissions still needed and the smallest next useful step.

Do not add a telemetry platform to measure one assignment. Do not infer economic
superiority from cheap coding, passing tests or one successful assignment.

## Selective escalation

Add work only to close an important uncertainty:

- A feasibility experiment for an uncertain boundary.
- A small independent oracle/property test for difficult logic.
- Differential checks for an existing implementation's observable behavior.
- Targeted stronger review/isolation for destructive or sensitive effects.
- A durable private reference only when risk or repeated reuse justifies its
  cost. Keep it outside the candidate and disclose shared-assumption risks.

This does not automatically switch workflows or add another specification kit.

## Unattended work

Use a supported persistent host/job when unattended execution is authorized.
Record where status, outputs and stop controls live, and verify actual progress.
A controller that only schedules work is not a competing repository writer:
the delegated implementation worker is the sole writer. Never wait for that
controller to exit while it is waiting for your result. Diagnose an actual
coordination failure rather than restarting an unchanged failure indefinitely.
