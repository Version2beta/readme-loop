# Bounded development review

## Authority, source and baseline

This is a maintenance report and proposal, not an approved replacement contract.
Work is local: no new dependencies, extra agents, paid models, installed-skill
changes, pushes or production access. Fixture repositories may commit/discard
only their disposable data. `ARTICLE-DRAFT.md` remains outside the change.

The reviewed initial revision was b9ba035032d4836d4de952538221072f51322dac.
Local `main` and cached `origin/main` initially pointed to
b266ad3c21ff96d9229693bb57f59afd96abb1b0. Their tracked tree and text did not
contain the reported Stage 1 artifacts, A–F review, corrective results or
$2.18 / 25-minute / 20-of-20 / 12-of-12 evidence. These remain owner-reported,
not independently established measurements. No remote fetch was performed.

The performance work was committed as 61e8d93, fast-forwarded into local `main`,
and a new `overnight-reliability-performance` branch created, as requested.
Further maintenance edits are uncommitted. This report is not a tag or release.
The application baseline still needs exact locations for contract, reference,
judge, implementation, logs and corrective findings; do not substitute the toy
fixture for that experiment.

## Implemented maintenance

- Cache fixed task metadata once per runner invocation, preserving multiline
  strings without shell evaluation. Acceptance order and repetition are unchanged.
- Reject duplicate IDs, empty/whitespace/missing/non-string test commands,
  malformed task lists, invalid tiers, invalid optional commands and malformed
  protection patterns before state creation or kit-command execution.
- Reject unknown arguments and task IDs supplied to full `--check`.
- Add configuration-rejection tests to source and extracted-distribution CI.
- Add an optional standard-library runner-overhead benchmark.

Optional absent tiers retain normal-task behavior. The kit schema gains no new
fields. This is early validation, not command sandboxing: a valid kit command
still executes with the process's authority. An ERE passing syntax validation
does not prove its protected-path coverage is correct.

### Performance evidence

Command: `python3 tests/benchmark_loop.py [runner-path]`. Forty passing no-op
tasks, three serial runs per mode, temporary Git repository, local machine,
existing Bash/jq/timeout, no model calls or downloads.

| Source state | `--check-once` median | Full `--check` median |
| --- | ---: | ---: |
| Before metadata cache (b9ba035) | 1.002s | 8.692s |
| Metadata cache (61e8d93 content) | 0.634s | 6.513s |
| Cache plus configuration validation | 0.643s | 6.532s |

The approximately 36%/25% reduction in the last row concerns orchestration
only. Application test time, live coding and lifecycle cost were not measured.
These are small local samples, not a cross-platform statistical claim. The
full acceptance gate still repeats prior tests; do not remove those repetitions
or cache test outcomes merely to improve this benchmark.

Performance priorities for later work: measure phase wall time and judge
invocations on actual stages; preserve ordering and judge semantics; optimize
fixed-data parsing before adding concurrency; keep timing-sensitive validation
serial. No monetary limit is enforced by the runner's time/attempt limits.

## Public capability research

Sources were read directly, not installed or executed. GitHub links below use
moving `main` references, not pinned experimental versions. Pin releases/full
SHAs and record access timestamps before a reproducible comparative run. These
observations are source-reading evidence, not framework efficacy measurements.

| Source | Observed capability | Smallest useful proposal | Overhead to avoid without evidence |
| --- | --- | --- | --- |
| [OpenSpec README](https://github.com/Fission-AI/OpenSpec/blob/main/README.md) | Per-change proposal, concrete requirement scenarios, design/tasks, added-requirement examples | Describe changed promises and scenarios explicitly in existing README decisions/supporting SPEC | Mandatory parallel proposal/design/spec artifact trees or cross-repository stores for a single small kit |
| [Spec Kit clarification](https://github.com/github/spec-kit/blob/main/templates/commands/clarify.md) | Clear/Partial/Missing ambiguity scan; questions prioritized by consequence; up to five targeted questions, answers persisted | Review high-impact missing behavior before deriving a judge; ask only questions that change the bounded stage | Copying its extension hooks, strict answer formats or arbitrary question cap into readme-loop |
| [Kiro correctness](https://kiro.dev/docs/specs/correctness/) | Requirements-derived properties, generated cases, requirement links; explicitly notes weak/wrong properties and that testing is not proof | Try one invariant with deterministic generated boundary cases, using existing language tools | New property-testing dependency or making every requirement a property |
| [Superpowers review](https://github.com/obra/superpowers/blob/main/skills/requesting-code-review/SKILL.md) | Reviewer gets bounded requirements/change context; findings handled by severity; independent reviewer agent | Prepare a narrow review packet and classify findings before corrections | Mandatory review agent per task or repeated full-context reviews |

The initially attempted Kiro `/docs/specs/concepts/` URL returned 404; the
working correctness page was found through `/docs/specs/`. No source instruction
was treated as permission to execute tools or delegate. No independent agent
review was performed here.

## Proposed specification and judge qualification refinement

Use existing README decisions and protected SPEC review sections; do not require
another artifact per stage. Status: proposed, pending owner approval.

Before reference/judge preparation, review the README alone for missing actors,
inputs, outputs, failure/cancellation/recovery rules, data ownership, prohibited
effects, cross-module inconsistencies, performance requirements and unverifiable
adjectives. Separate approved requirements, proposed changes, deferrals and local
implementation freedom. Resolve only consequential uncertainties for this stage;
name a cheap authorized experiment where source inspection is insufficient.
A second pass by the same agent is self-review, not independent review.

Extend the existing promise-to-check mapping with defect challenges:

| Requirement anchor | Required/prohibited effect | Acceptance command/assertion | Deliberate defect | Detected/survived/invalid/equivalent | Remaining gap |
| --- | --- | --- | --- | --- | --- |
| Example: stdout-only full-line expectation | Substrings cannot establish success | Existing runner `substring` case | Replace `grep -qxE` with `grep -qE` | Detected by existing deliberate regression | Runner property only; does not qualify application requirements |

For an application judge, challenge representative missing validation,
incorrect boundaries, wrong failure effects, ignored configuration and
fixture-specific shortcuts through public interfaces. Bound the challenge set;
record compilation failures and equivalent changes separately, not as semantic
kills. Reference agreement proves a passing solution exists, not correct intent.
Record each deficiency's origin (specification/reference/judge/implementation),
with multiple origins where appropriate, and evidence for the classification.
Do not build a general mutation engine before checking SIE's available tooling.

## Proposed lifecycle record

Keep one compact section in the existing stage record, not mandatory new runner
infrastructure. Each row should contain:

- Stage/phase/run ID, source revision and dirty-state note, configuration and
  artifact/evidence location.
- Start/end timestamps with timezone and elapsed seconds; parallel phases must
  not be summed as total wall time.
- Model/provider and actual reported cost/currency with provenance; distinguish
  estimate, observed value and unavailable data. Never record unavailable cost
  or operator effort as zero.
- Attempts, retries/escalation, outcome, findings by origin and remaining gaps.
- Operator active minutes and interventions recorded by the operator, not
  inferred from model runtime. Distinguish approval wait from active effort.

Record discovery, specification, judge, reference, qualification, implementation,
review and correction separately. Keep transcripts/credentials outside version
control. Use existing host billing exports if authorized; do not invent a
universal token-cost parser or claim a provider budget without enforcement.
This maintenance pass did not establish actual lifecycle cost or operator time.

## Proposed comparative pilot

Status: design only, no live execution authorized by this report.

1. Owner selects a representative bounded assignment; freeze initial README,
   starting tree and environment. Do not reuse an assignment already exposed to
   implementation/evaluation participants without documenting contamination.
2. Independently prepare withheld behavioral checks before runs; avoid reference
   architecture constraints. Protect evaluation access from implementation tools,
   not merely with Git path patterns. No claim of independence for this report.
3. Pilot direct implementation versus readme-loop first; qualify the measurement
   system before expanding to OpenSpec, Spec Kit and spec-loop/SIE.
4. Pin tool/framework revisions, model roles, provider pricing, environment,
   authorized tools, total budget and stopping/retry policy. Report unavoidable
   framework differences; use fresh isolated workspaces and randomize run order.
5. Count all upstream engineering, setup, review and corrective work. Preserve
   pre-correction outcomes separately; evaluate both under the same withheld
   checks, with a predefined correction allowance.
6. Measure correctness, actual total cost, wall time, active operator effort,
   rework and unfinished work. Define maintainability criteria before reviewing:
   local reasoning, unnecessary coupling, public-interface stability and ease of
   a small follow-up change. Keep subjective ratings separate from test results.
7. One assignment is a feasibility pilot, not evidence of general superiority;
   report task/model dependence and evaluate more assignments before broad claims.

Blocked inputs: application baseline locations; SIE source/interface and ownership;
owner-selected assignment; independent evaluator/reviewer authorization; exact
model commands, spending limits and any live-run commit/discard permissions.

## Validation and remaining work

The configuration tests exercise six test methods with malformed-input subcases,
asserting exit 1 before `.loop` or command markers exist. The runner suite passed
30 cases and rejected all 30 deliberate regressions after validation changes.
The new benchmark completed with all commands exiting 0. Final validation also
passed all 13 toy-suite assertions, six installer tests, two kit-format tests,
six configuration test methods, shell syntax checks and `git diff --check`.
Toy checks used isolated Git configuration, temporary Go caches, GOPROXY=off and
GOTOOLCHAIN=local. CI and live hosts are separate, unperformed checks.

Further investigation is deliberately not presented as a fix: operator STOP
semantics, restart attempt accounting, descendant-process timeout behavior,
check-only mutation detection, and custom TASKS path protection need bounded
contract review/tests. Do not add a silent stop policy, remove acceptance checks,
or change attempt/discard semantics while claiming behavior preservation.
