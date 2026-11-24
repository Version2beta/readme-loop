# Protected-surface review template

Copy this review into a protected section of the kit's `SPEC.md`. Complete it
before kit acceptance, handoff, or any separately authorized commit. Repeat for
overlays and judge changes. This record is engineering evidence, not automatic
approval or permission to commit. Replace instructions with concrete paths,
contract sections, and evidence; use explicit `none` for empty inventories.

## Protection inventory

List contracts, tests, fixtures, golden outputs, and judge infrastructure with
actual paths and matching `tasks.json` EREs. Include runner-added protection.
Check matches after JSON decoding against the supplied tree and representative
future production paths; broad directory patterns can freeze future code too.
Confirm all verification dependencies are protected and implementation files
and progress notes remain writable except justified exceptions below.

## Protected production artifacts and interfaces

List **every** protected production artifact and every fixed production
interface (including interfaces enforced by test imports or stubs). A declaration
or complete-file label is not a reason. Include existing approved APIs if fixed.

| Path or interface | Contract anchor / required verification property | Why protection or a fixed interface is necessary | Smallest alternative considered and why inadequate | Engineering responsibility already supplied |
| --- | --- | --- | --- | --- |
| Fill in, or explicitly state none | | | | |

Prefer public-interface checks and external simulations. A legitimate minimal
seam can be fixed when necessary, but protected infrastructure must contain no
application policy. For example, a fake device may return an I/O error; it must
not decide which drives qualify, how retries work, or which work runs next.
Production data models and Linux access implementations are not automatically
verification infrastructure. Record any unavoidable limits of simulation and
which real effects still need integration evidence.

## Engineering ownership

- **Already fulfilled by the kit:** enumerate production behavior/design supplied
  by complete files, stubs with logic, adapters, generated code, and fixed types.
  Distinguish test harness behavior from application behavior; state none if none.
- **Remaining for the implementation agent:** enumerate required production work
  and design freedom, including data models, package boundaries, algorithms,
  concurrency, OS access, and architecture unless explicitly constrained.
- **Reference separation:** identify the starting-file provenance; confirm no
  reference production code was copied merely to make testing convenient.
  Independently required public schemas or minimal seams need their own rationale,
  not wholesale reuse of reference packages.

## Judge-imposed architecture

| Test / build rule / fixture / interface | Architectural constraint | Explicit contract anchor or necessary verification property | Less restrictive alternative and decision |
| --- | --- | --- | --- |
| Fill in, or explicitly state none | | | |

Include constraints from internal imports, constructors, package layout, build
commands, and structural checks, not just protected files. Structural checks
may establish an explicit property such as side-effect isolation; they must not
freeze incidental reference choices. Escalate newly required application
architecture for contract approval rather than silently treating it as a test need.

## Verification and acceptance evidence

- Every new implementation task fails on stubs; every task and whole-stage
  check passes on the private reference with the unchanged runner's judge.
- Map behavioral promises (including failures and prohibited effects) to checks.
  Record plausible incorrect implementations challenged and what rejected them.
- Record ambiguity review, residual judge weaknesses, missing integration
  evidence, and deferred questions. Reference success alone resolves none of these.
- Confirm surface reduction preserved behavioral coverage; record changes and
  evidence, or explicitly state no checks were removed or weakened.
- State review outcome and unresolved blockers. Unjustified production protection
  or architecture blocks kit acceptance; fix it or obtain the necessary contract
  decision and reverify. Record only approval actually obtained.
