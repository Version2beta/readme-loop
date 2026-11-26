---
name: readme-loop
description: Build or extend software from an agreed README, using useful implementation milestones and independently owned behavioral acceptance. Use for README discovery, clarification, implementation, evaluation and bounded corrective work. References and elaborate kits are optional, not prerequisites.
license: MIT
metadata:
  version: "0.2"
---

# readme-loop

Agree through the README. Implement freely. Accept through behavioral evidence.
Optimize total engineering cost and time to a useful, adequately correct result,
not coder cost, artifact count or verification volume in isolation.

This is an independent workflow, not a front end to another specification loop.
The default is **README → acceptance → implementation → evaluation → delivery**.
No dedicated specification, private reference implementation, task manifest,
stubs, copied runner or new agent is required merely to use this skill.

Resolve bundled paths from this skill's directory. Work in the owner's supplied
project, or the current directory if unambiguous—not in the installed skill.
Installation and invocation are described in [README.md](README.md).

## Authority and boundaries

- Inspect applicable guidance and relevant Git state; preserve existing work.
- A README is a candidate contract, not automatic approval. Obtain actual approval
  of the milestone and changed promises. Honor existing approvals without asking
  again; never label recommendations or silence as approval.
- Work within authorized local actions. Paid model calls, additional agents,
  commits, discards, installation, remote changes and production actions require
  applicable explicit authorization. Confirm authentication/billing source, exact
  model commands, spending cap and stop conditions before paid unattended work.
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
Ask only questions that change the next milestone's observable behavior,
compatibility, ownership, important failure semantics, feasibility or authority.
Do not expand a small assignment into the ideal finished product.

Choose one useful milestone. State its scope, acceptance, important exclusions
and local implementation freedom. Private packages, algorithms and internal types
belong to the implementer; contractual APIs and observable effects do not.
Leave independent future questions deferred, with a resolution point.

Keep material decisions and their rationale/status (proposed, approved, deferred,
superseded) concise in the README. Update the actual promises too. Use module
READMEs or supporting schemas only where they resolve real ambiguity. Do not
require an audit history of every implementation choice or a duplicate SPEC.

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

## 3. Implement a coherent milestone

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

For a meaningful milestone, seek one bounded independent review when authorized,
focusing on requirements, consequential failures and acceptance gaps. Independent
review needs a separate execution context; self-review is not independent, and
same-model correlation remains a limitation. Do not launch reviewers without
permission or claim review/approval on someone's behalf.

Batch findings into one correction pass and recheck the affected guarantees plus
necessary regression coverage. Further broad review requires a material reason,
not merely another minor finding. A serious unresolved defect blocks acceptance;
a review/correction limit is not permission to ship it. Record low-impact or
unrelated improvements without extending the milestone indefinitely.

Stop when the milestone meets its agreed acceptance/review boundary, when an
explicit time/spend/retry limit is reached, or when safe progress requires a
contract decision. Report partial/blocked work honestly; do not spend the budget
merely because it remains available.

## 5. Deliver evidence and economics, not ceremony

Use one concise handoff in an existing record or response:

- Outcome and source state; selected README paths and scope.
- Commands/results and user-facing evidence; important gaps and remaining risks.
- Measured elapsed time and actual reported model cost for preparation,
  implementation, evaluation/review and correction where available. Separate idle
  waits and operator effort; unavailable values are unknown, never zero. Label
  estimates, billing reservations and reported costs separately.
- Deferred decisions, permissions still needed and the smallest next useful step.

Do not add a telemetry platform to measure one milestone. Do not infer economic
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

## Unattended work and old projects

Use a supported persistent host/job when unattended execution is authorized.
Record where status, outputs and stop controls live, and verify actual progress.
A controller that only schedules work is not a competing repository writer:
the delegated implementation worker is the sole writer. Never wait for that
controller to exit while it is waiting for your result. Diagnose an actual
coordination failure rather than restarting an unchanged failure indefinitely.

Old v0.1 projects may already contain `tasks.json`, `SPEC.md` and `loop.sh`.
Do not silently migrate them, reinterpret their acceptance or launch their
automatic commit/discard loop. Their historical format is documented in
[references/kit-format.md](references/kit-format.md). It is not the new default;
new readme-loop milestones do not depend on that format or another project.
