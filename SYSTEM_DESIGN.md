# Seer: an agent-legible learning system

**Status: design baseline for the schema-2 cutover.** Beads epic `srrs-login-epic-lyy` tracks delivery. [README.md](README.md) documents the implemented protocol and runtime limitations; installed tool definitions and source settle current behavior. The pre-cutover inventory below is historical. Never call a tool that the installed desk does not advertise.

## Purpose and design decision

Seer turns source material into a person's durable, correct understanding. Cards, captures, assistant requests, context sources, and review schedules are different stages of that process, not independent products. The agent's job is to help the person learn the right thing, not to maximize generated cards, provider calls, or autonomous activity.

The central design decision is to make three contracts fit together:

1. **Knowledge:** what was observed, from which exact evidence, with what coverage and uncertainty?
2. **Control:** which typed change is permitted, against which state, under whose authority?
3. **Proof:** what actually happened, how can it be reconciled, and what is safe to reuse?

Optimize in this order: authority and correctness; useful learning outcomes; recoverability and legibility; then latency, context, compute, and storage. A cheap answer based on silently omitted evidence is not an optimization. An explicit evidence gap or a decision to make no new cards can be a successful result.

The system should get easier to operate as it accumulates supported knowledge, not harder as it accumulates transcripts. It must remain usable with a fresh agent session, a small context window, an unavailable provider, or a disconnected bridge.

## Pre-cutover baseline

This inventory describes historical commit `d1f8093c3d49c5a2d7015b9ffbed121100b28cf6`, before implementation of this design.

| Existing mechanism | Consequence for this design |
| --- | --- |
| `%seer` owns versioned Gall state; MCP threads scry and poke it. | Extend this authority. Do not add a bridge database or agent-side truth store. |
| Captures contain proposals; approved cards have capture/source/rationale provenance. | Reuse these objects for evidence-backed creation; current provenance is not a versioned citation history. |
| Browser approval applies capture proposals and library plans. MCP also exposes direct `create-stack` and `add-card`. | Approval is not currently universal. The target planner surface removes the direct-write bypasses. |
| Browser **Edit** authorizes a single-card edit; applying it checks the original title/front/back. | Preserve this narrow explicit delegation, while adding revision and outcome guarantees. |
| Library plans revalidate original values before application. | Preserve all-or-nothing validation; extend it rather than inventing a second planner/validator. |
| Context jobs and login transitions use nonce-bound bridge proofs. Card/change worker transitions use the ship cookie and worker IDs. | Worker identity and authorization are not presently uniform. A worker label must not become a credential. |
| Some MCP results are constructed from submitted values after a poke. | A successful tool response is not uniformly a committed-effect receipt. Reconciliation is a first-class requirement. |
| List and planning tools can return whole collections; context prompt assembly clips source text without a coverage manifest. | Narrow reads and visible omissions must precede more ambitious agent reasoning. |
| The bridge processes context, card, and change work serially; login children are supervised separately. Startup recovery handles contexts and logins, not a common leased-job protocol. | Keep the useful separation, but make ownership, interruption, and resource bounds explicit. |
| Library plans read library state during processing; card requests retain their submitted card snapshot. | Record when each input was selected. Request time and observation time are different facts. |
| Shared stacks use live subscriptions; explicitly shared Clay files are public snapshots for other ships. | Remote material is evidence, not local write authority. Unsharing cannot recall bytes already copied. |

Source locations: [domain types](desk/sur/seer.hoon), [agent state and action gates](desk/app/seer.hoon), [MCP tools and JSON projections](desk/lib/seer-mcp.hoon), [provider execution](bridge/seer-ai-bridge.mjs), and [server-rendered interface](desk/app/seer/index.hoon). At the baseline revision, `poke-seer-action`, `change-valid`, `apply-operations`, `buildContextBlock`, `processQuestion`, and `processChange` were integration boundaries; the linked files now contain the cutover implementation.

## The abstraction stack

Each layer consumes references and guarantees from the layer below. Higher layers may propose changes; they may not manufacture lower-layer facts or permissions.

| Layer | Canonical concepts | What the next layer may rely on |
| --- | --- | --- |
| Identity and authority | Ship ownership, typed references, incarnations, revisions, effective capabilities | An unambiguous subject and an enforceable permission boundary |
| Evidence | Source locator, immutable snapshot, excerpt, coverage, derivation | Exactly what was available, what was read, and what remains unknown |
| Learning state | Card content, provenance, local scheduling state, actual learner observations | What is being learned, separately from whether its claims are true |
| Deliberate work | Existing capture, question, change request, and ingestion job; goal and stopping condition | A bounded, resumable unit of intention with explicit inputs |
| Effects and proof | Typed proposal/operation, approval, precondition, committed receipt | What was proposed versus what changed, and why replay is safe or unsafe |
| Surfaces and adapters | Browser, MCP, local bridge, provider CLI | Consistent views and actions over the same domain contracts |

The feedback path is **evidence → proposal → authorized card change → learner observation → better evidence selection or a new proposal**. It is not model output → accepted fact. This is a conceptual graph of typed links in existing nouns and maps, not a requirement for a graph database, generic workflow engine, or vector store.

## Contract vocabulary

### One owner for each fact

- `%seer` owns library state, selected evidence references, work state, approvals, and effect receipts.
- Clay or a remote publisher owns live source content. Seer owns the snapshot it actually retrieved, not a claim about the source's present contents.
- The bridge owns local process supervision and provider-account access. Its durable progress is recorded on the ship; its in-memory process table is not a second queue.
- A provider produces candidate text or typed proposals. It neither attests factual truth nor commits library state.
- The person owns learning objectives, approval decisions, explicit editing grants, and recall grades. An agent cannot grade on the person's behalf to improve its metrics.
- Beads owns repository implementation work. A Seer `%desk` request is a brief, not an executed code change or another repository issue tracker. Handoff records the Seer request reference in the bead and the bead reference in the brief; status is not independently maintained in both.

### Stable references and separate revisions

Use existing ship/stack/card/request IDs, never display titles as identity. A typed `ref` contains the relevant existing keys plus an incarnation so deleting and recreating the same slug cannot satisfy an old precondition. During pre-release, state-shape changes reset the development agent rather than migrating old data.

Revisions answer different questions:

| Field | Meaning |
| --- | --- |
| `schema_version`, `capabilities_revision` | Which protocol and effective tool contract the caller is using |
| `state_revision`, `observed_at` | Which coherent local observation produced a response; not a global cross-ship snapshot |
| `content_revision` | Monotonic editorial state, including A→B→A changes; used for content edits |
| `review_revision` | Learner scheduling/grade state; an unrelated grade must not invalidate an editorial change |
| `snapshot_ref`, `digest` | Exact normalized source bytes and their identity; a digest proves identity, not truth |
| `work_ref`, `attempt`, `lease` | Durable request identity, a particular execution, and its current server-issued ownership |
| `operation_id`, `idempotency_epoch` | One caller intent within a server-advertised replay namespace |
| `receipt_ref` | An authoritative recorded outcome, not a tool's echo of its input |

Expose revision fields only with their documented domain. `last-modified`, source retrieval time, and model confidence are not substitutes for a content precondition. Deletion and absence require explicit existence/incarnation preconditions too.

### Shared protocol, not a universal action tool

Keep domain-specific tools. Add common envelopes and use one domain validator from browser and MCP paths. Required response information is:

- Identity, schema, effective scope, and observation revision.
- Bounded data plus `complete`, `next_cursor`, and omissions with reasons. A complete empty set differs from unknown, unavailable, unauthorized, or not loaded.
- References to legal next actions and their unmet prerequisites. Tool schemas come from discovery; do not repeat full schemas on every row. Suggestions are advisory, never grants of authority.
- Structured outcomes such as `ok`, `blocked`, `conflict`, `invalid`, `unauthorized`, `budget_exhausted`, and `outcome_unknown`; stable reason codes, affected references, and a valid recovery path accompany human-readable explanation.
- An effect disposition of `none`, `staged`, `committed`, or `unknown`. Never report `none` when a transport failure leaves a commit uncertain.

Authenticate before exposing object details. Error responses must not reveal private subjects to unauthorized callers. Validation rejects oversized fields and batches in the authoritative action gate, not only in the bridge parser.

Capability discovery distinguishes planner operations, paired-worker operations, and operator approval/admin operations. The server derives effective capabilities from authenticated authority and the actual entry point; an `actor` or `worker_id` field is only attribution. Planner-facing tools do not expose approval, and worker mutations require the separate paired capability. Local owner administration remains an explicit trusted boundary.

This interface boundary is not a sandbox for an agent given the owner's Dojo or HTTP session plus arbitrary request tools. Such a caller can act as the owner outside MCP. Do not describe the current ship-cookie connection as a least-privilege credential. Restricted planner delegation requires the MCP transport to attest a scoped principal; a tool argument cannot manufacture that identity. Establish this transport contract in the foundation slice before advertising scoped delegation. Until it is supported, label the connection `owner-trusted` and reject jobs requiring stronger isolation rather than silently downgrading them. Operator credentials must remain outside provider context.

## Observation and navigation

The proposed read-only **`seer/agent-context`** is the entry point. It returns a compact orientation, not the whole library:

- Ship identity, protocol/capability revisions, requested scope, provider availability with last-observed times, and published limits.
- Relevant learning objective, stack/card counts, due-review counts, open captures/requests, unresolved approvals, and recovery blockers, all as bounded summaries and references.
- Evidence availability/freshness/coverage and an explanation of what was omitted.
- Valid ways to expand the selected subject, continue existing work, or stop.

With no selected scope, return a bounded library index and open-work index. A recent selection is a navigation hint, never an implicit mutation target. Read-only discovery must work without a paired bridge or logged-in provider.

Extend `list-stacks`, `get-stack`, `list-captures`, `learning-context`, `state-context`, and queue list tools with scope, status, projection, and cursor parameters. Retrieve metadata first, exact selected card content second, relevant evidence excerpts third. Add narrower scries behind these queries: slicing a fully serialized `ai-state` at the MCP boundary is not a resource improvement.

The server advertises default and maximum page counts, UTF-8 response bytes, excerpt bytes, and cursor lifetime; callers may request smaller bounds. A row that cannot fit returns a bounded reference/summary, not a silently cut record. Ordering is deterministic. Cursors bind scope, filters, ordering, and observation revision. An intervening change either preserves that snapshot or produces `snapshot_expired` and an explicit refresh path; it must not silently skip or duplicate rows.

A scoped `since_revision` query returns changed references or `reset_required`, not an indefinitely retained global event log. When unchanged, do not return unchanged source bodies or completed history. Authorization is checked again on every expansion and cache hit.

### The operating loop

| Step | Minimum sufficient observation | Action and stopping rule |
| --- | --- | --- |
| Orient | Identity, scope, capabilities, open work, limits | Resume a matching intent before creating another one. Stop if required authority is absent. |
| Focus | Objective, selected card/stack revisions, evidence manifest | Retrieve only evidence that could affect the decision. Stop on missing necessary evidence rather than infer it. |
| Prepare | Exact input packet and relevant prior decisions | Produce the smallest useful proposal, explanation, or typed plan. Zero new cards is allowed. |
| Check | Deterministic preview, evidence support, predicted effects, budget | Resolve contradictions or return a named blocker. Do not pay for another model call to repeat a deterministic failure. |
| Authorize and act | User approval or a narrowly scoped existing edit grant | Submit the exact authorized operation. A planner never grants itself approval. |
| Reconcile | Receipt and affected current references | Establish staged versus committed effect. After ambiguity, inspect before replaying. |
| Accrete or stop | Outcome, source lineage, explicit feedback | Retain useful structured evidence; archive noise. Finish when the objective is satisfied or a named budget/authority/evidence boundary is reached. |

A resume record is the existing request plus its goal, scope, acceptance/stop condition, selected packet, completed receipt references, current attempt, remaining budget, and blocker/next action. It is not a saved conversation or private chain of thought.

## Evidence and context

### Locator, snapshot, excerpt, claim

A source record describes where material comes from and where it applies. Refreshing that locator creates a new immutable snapshot. An excerpt identifies exact ranges in that normalized snapshot. A generated explanation or summary is a derived claim referencing those excerpts, not a replacement source.

Snapshot metadata includes owner and scope, kind, original locator, retrieval time, origin revision when available, normalized-content digest, extraction method/version, content byte count, and coverage (`full`, `excerpt`, or `listing`). Freshness is `current`, `stale`, or `unknown` relative to a stated check; a recent fetch is not a claim of accuracy. Web redirects retain the final locator as provenance without hiding the original.

Validate citation identity and quotation mechanically: the snapshot must belong to the selected packet, ranges must exist, and quoted text must match the normalized source. Label inference separately from quotation. These checks establish provenance and quote accuracy, not semantic entailment or factual correctness; they cannot turn a well-formed model answer into verified knowledge.

A listing establishes that paths were listed, not that their contents were read. Remote publishers are not part of a transactional local snapshot. References to remote data always identify the locally observed version and time.

### Inspectable context packets

For each attempt, resolve context once into an inspectable packet shared by the browser, MCP inspection, and provider prompt builder. Pin the card revision, selected snapshot refs, exact excerpts, objective, and necessary prior results. Include:

- Each included source and why it is relevant, with precise coverage and byte counts.
- Each selected but unavailable, failed, stale, excluded, or budget-omitted source and its distinct reason.
- Contradictions and unsupported claims as unresolved facts about the packet, not silently reconciled model guesses.
- The selected model/profile, prompt/output-schema version, input budget, and applicable disclosure policy.

Selection is deterministic for the same inputs and budget. User-selected relevant evidence wins over incidental history; stable reference order breaks ties. If mandatory evidence does not fit, return `budget_exhausted` with a narrower retrieval option, not a successful incomplete answer. Truncation must preserve UTF-8 boundaries and state its exact omitted ranges. Titles, delimiters, history, and metadata count toward the total prompt budget too.

Expose authorized attach, refresh, and archive actions through MCP equivalents of existing context actions. Permit evidence scoped to a capture or change request before its target stack exists; do not force creation of a live empty stack just to collect evidence. Keep source acquisition restrictions at the acquisition boundary, including public-network checks and remote-sharing permissions.

Archive excludes a source from future selection; it does not rewrite a queued packet. Refresh invalidates dependent summaries/retrieval caches, but not the historical record of what an old request saw. Reusing a stored snapshot in a new provider call still requires current access and egress permission. A queued request does not defeat a later permission revocation: block its dispatch and require a newly authorized attempt.

### Privacy and trust

All source bodies, card text, prior model results, and retrieved instructions are untrusted material. None may change tool permissions, provider choice, budgets, or system instructions. Explicit preferences are typed, scoped, user-authorized metadata, not instructions harvested from a note or web page.

Show exactly which material will leave the ship for the selected provider, including local/ship files. Sharing a stack must not implicitly share its local context sources, assistant history, grades, or provider-bound packets. Publishing a Clay file is an explicit public disclosure; unsharing cannot revoke remote copies. Do not reinterpret existing public sharing as private by changing documentation alone.

Secret values, bridge proofs, ship cookies, login paste-back codes, and provider credentials never belong in orientation, evidence packets, receipts, retained diagnostic bodies, or generated summaries. Provider CLIs may use their own local account credentials, but must not inherit unrelated ship/bridge secrets.

## Safe effects

### Authority follows intention

| Intention | Target authority and effect |
| --- | --- |
| Inspect, explain, compare, propose | Planner may read allowed scope and produce staged artifacts; no library mutation implied. |
| Capture cards or reorganize a library | Planner stages proposals/typed operations; the person reviews exact effects before commit. Remove planner-facing `add-card` and `create-stack` bypasses at cutover. |
| User explicitly chooses card **Edit** | A paired worker may complete that one requested edit against the pinned card revision. The grant does not permit another card, grading, sharing, or a library plan. |
| Fetch a source or run a provider job | Paired worker acts within the admitted request, allowed destinations, lease, and budget. |
| Approve, grade, publish, pair, rotate credentials | Operator surface only; not planner or provider authority. |
| Change Seer itself | Produce a repository implementation brief. Neither approving prose nor finishing a provider call installs code. |

A plan contains the goal, affected references, original/precondition revisions, typed ordered operations, evidence/rationale, predicted effects, and an exact plan digest. It must say whether it changes review membership and whether it leaves learning state untouched. A correction never silently resets recall history or manufactures a review.

### One validator, one commit boundary

The proposed read-only **`seer/preview-change`** uses the same deterministic candidate-state validator as commit. It reports a bounded before/after diff, touched revisions, conflicts, required authority, and predicted effects. It does not mutate, call a model, or reserve state indefinitely.

Validate an ordered batch against a private candidate state, including intermediate constraints. This permits a new stack plus its cards in one approved plan; conflicting repeated writes must be rejected or explicitly represented as a coherent sequence, never resolved by incidental list order. Preserve provenance for cards created through plans as well as captures.

Approval binds the exact plan digest, subject incarnations, relevant revisions, and allowed effects. Immediately before commit, validate those preconditions again in the same Gall event that applies the complete batch and records its receipt. A failed precondition produces no partial library change. Replanning after a conflict creates a new reviewable version; never silently rebase an approved plan.

### Receipts and ambiguous outcomes

Every mutation carries an epoch-scoped idempotency key and canonical payload digest. The authoritative action gate, not an MCP preflight scry, owns replay detection and outcome recording:

- Same key and same payload returns the stored result without a second effect.
- Same key with different payload returns `conflict`.
- A committed receipt identifies intent, actor/authority, work/attempt when applicable, input revisions, plan digest, affected before/after references, result disposition, and commit revision.
- A staged result identifies the artifact awaiting approval. A provider answer records that an answer was stored, not that its claims were verified.
- The proposed read-only **`seer/get-operation-result`** reconciles a lost response by key. An absent result during ongoing execution is not permission to rerun.

Receipts are not retained without bound. Advertise replay retention, retain receipts or compact outcome tombstones for the entire accepting epoch, and retire that epoch before discarding its deduplication state. Reject keys from retired epochs as `replay_expired`; never interpret an old retry as a new write. When old effects can no longer be established, expose `outcome_unknown` and require inspection and renewed explicit authorization.

Exactly-once library effects are possible at the Gall commit boundary. Exactly-once external model execution or billing is not promised. After ambiguous external completion, preserving an explicit unknown outcome is safer than claiming an automatic retry is free.

### Worked control trace

A person requests a correction to one card. The agent inspects its content revision and finds a listing-only source. It expands the relevant file, obtains a cited snapshot, and prepares a bounded edit using that evidence. Before completion, the person edits the same card.

The old content precondition now fails: no overwrite, no automatic broader search, and no speculative retry. The result links the current card, the old packet, and the conflict. A replacement attempt needs the updated subject and authorization. If instead the original edit committed but its response was lost, lookup returns the original receipt and no second edit or provider call is needed. These are different states and must never share a generic “try again” instruction.

## Execution and recovery

Add common execution metadata to existing runnable records; do not replace their domain state machines. Captures remain proposal containers, not jobs. Represent execution (`queued`, `running`, `blocked`, `succeeded`, `failed`, `cancelled`) separately from effect disposition (`none`, `staged`, `committed`, `unknown`). For example, a library planning attempt can succeed while its effect remains staged and its domain status is awaiting review.

A claim atomically assigns a worker, attempt number, and expiring server-time lease. A heartbeat extends only that current attempt. All worker mutations, including model catalog publication, require the paired capability; worker labels alone confer nothing. Nonce proofs cover the operation, payload, attempt, and lease. A shared bridge secret defines one trusted bridge authority, not cryptographic isolation between worker names.

Completion, failure, cancellation, and recovery are serialized at the authoritative gate. An expired or superseded worker cannot commit, even if it later returns a valid-looking result. Recovery must not steal another live lease. Secret rotation invalidates old proofs and attempts; recovery requires the newly authorized bridge rather than merely changing a worker string.

Persist bounded checkpoints for selected inputs, provider-started, validated result available, and receipt reconciliation. Checkpoint only data needed to resume; never retain hidden reasoning. If a provider result was stored before a crash, reuse it only under the same packet, authority, model/schema, and effect preconditions. If the provider may have run but no result survives, report that ambiguity before another billable attempt.

Budgets are part of admission and survive restart: deadline, allowed provider/profile, maximum invocations, input/excerpt bytes, output bytes, operation count, and concurrent work. Apply hard bounds to stdout, stderr, output files, history, and parsed responses. Overflow or an incomplete provider result is not a successful full answer. Usage reported by a CLI is observed usage; unavailable token or credit accounting is `unknown`, never zero.

Start with one provider invocation per admitted attempt and no automatic escalation. A different model, larger budget, or another attempt requires permission within the original grant or renewed authorization. Deterministic validation, filtering, and rendering never need a model. Cache derived work only by exact input revisions, scope/egress policy, prompt/schema version, and model/profile; check authority again before reuse.

Use bounded queues with fair selection so source ingestion or one slow provider does not indefinitely starve unrelated work. Defer costlier concurrency until leases and output bounds hold. Queue reads use metadata/status filters and change watermarks rather than downloading completed bodies on every poll. A disconnected bridge or unavailable exact profile produces a named blocker, not silent fallback.

Login retains separate interactive supervision and one-shot secret semantics. A lost consume-code response must not turn a general-purpose receipt into a credential recovery channel; reconcile public status or start a newly authorized login. Cancellation requests terminate local children where possible and fence later commits, but cannot promise to reverse an external provider side effect or charge.

The no-tools provider contract must be enforced through supported CLI restrictions and process/environment isolation, not only prompt text. If an adapter cannot enforce its declared capability envelope, mark it unsupported for that job instead of claiming isolation it does not have.

## Accretive learning

Accretion means less repeated investigation and better-supported learning, not unrestricted memory growth.

Retain a small set of useful linked artifacts:

- Source snapshots/excerpts and revision-linked card provenance.
- Approved and rejected proposals, optional explicit rejection reasons, and correction lineage.
- Relevant explanations with their evidence and generation metadata, clearly labeled as derived claims.
- Actual learner observations linked to the card revision studied, separate from editorial truth.
- Explicit, scoped user preferences and authoritative effect receipts.

Before generating cards, inspect related cards, active proposals, and matching prior decisions. Use IDs, scope, normalized content, and source references for deterministic candidate retrieval first. Spend on semantic comparison only when ambiguity would change the action. A previous rejection suppresses identical unsolicited resubmission, but does not establish that a claim is false. An explicit new goal or changed evidence may justify a new proposal linked to the old decision.

Every proposed card should state one learning objective, its supported claim, source excerpts, why existing cards are insufficient, and any unresolved caveat. Card count is a ceiling selected for the task, not a quota. The current prompt's fixed 5–12-card instruction must become a bounded preference, with zero supported additions permitted.

Review difficulty can suggest an unclear card, missing prerequisite, or misconception; it cannot identify which explanation is correct without evidence. Keep “the learner recalled this,” “the person approved this,” and “this source supports this claim” distinct. No automatic rewrite of approved knowledge, grading, preference inference, scheduler replacement, or model self-training is introduced by this design.

Derived artifacts carry explicit dependency references. A changed or revoked source invalidates their eligibility for current retrieval, without falsifying the history of an earlier answer. Contradictory evidence remains visible until resolved through an explicit decision.

Retention follows usefulness and reachability. Share identical stored snapshot bodies within the authorized scope instead of copying them into every request. Archive context when its owning subject is deleted; collect unreferenced bodies and obsolete working history under advertised policy. Preserve compact lineage/outcome tombstones while they are needed for interpretation and replay. Distinguish archive from explicit purge: purge makes historical evidence unavailable, and dependent summaries must not leak its contents through another route. Application deletion is not a claim to erase Urbit event logs, backups, provider records, or remote copies.

Measure supported artifact reuse, unnecessary repeated proposals, source-related corrections, and storage retained per active learning artifact. Do not use card volume, model self-confidence, raw approval rate, or fast completion as sole quality targets. Learner outcomes are observed under changing material and behavior; do not claim causal improvement from a small before/after sample.

## Human and agent surfaces

Preserve the existing server-rendered Hoon/HTMX interface and its keyboard/no-JS behavior. Do not add a dashboard or client-side state store to explain state the server already knows.

The common information hierarchy for a capture, card request, or change is:

1. Objective, subject, current execution state, and whether anything changed.
2. The next valid action or blocker, with the reason and required authority.
3. Evidence coverage and provider-bound material.
4. Reviewable before/after effects or the answer, with caveats and sources.
5. Receipt, prior attempts, and deeper provenance on demand.

“Ready for review,” “answer stored,” and “applied” are distinct labels and machine states. Missing evidence, unavailable provider, stale plan, expired lease, and unknown outcome each need a different recovery action. A disabled action explains the unmet precondition rather than forcing trial-and-error tool calls.

Browser and MCP views derive from the same records, validators, and packet builder. Approval shows the exact plan version and scope; a stale approval shows a new diff before another approval. Destructive effects and public disclosure are explicit, not buried in assistant prose. Compact layouts and keyboard navigation retain the same evidence and decision path with progressive disclosure; focus survives fragment changes. Accessibility and no-JS operation are interaction constraints, not a second business-logic implementation.

## Delivery and proof

### Durable implementation map

Beads is the source of task status, acceptance criteria, and dependency edges. This table maps contracts to implementation slices; it is not another task checklist.

| Bead | Contract owned |
| --- | --- |
| `srrs-login-epic-lyy.1` | [Identity, revisions, protocol, effective authority](#contract-vocabulary) |
| `srrs-login-epic-lyy.2` | [Bounded orientation and scoped reads](#observation-and-navigation) |
| `srrs-login-epic-lyy.3` | [Evidence versions and inspectable packets](#evidence-and-context) |
| `srrs-login-epic-lyy.4` | [Authoritative previews, approval, and receipts](#safe-effects) |
| `srrs-login-epic-lyy.5` | [Fenced execution, recovery, and budgets](#execution-and-recovery) |
| `srrs-login-epic-lyy.6` | [Evidence-backed learning and retention](#accretive-learning) |
| `srrs-login-epic-lyy.7` | [Human/agent surface parity](#human-and-agent-surfaces) |
| `srrs-login-epic-lyy.8` | Cross-boundary cutover and verification |

The stack-context orphan bug `srrs-login-epic-prd` was tracked separately as a release-gate dependency. The keyboard-selection work `srrs-anm` remains independently owned. Consult Beads for current status; completed context, sharing, login, and alignment work is reused, not reopened under new names.

Establish shared noun/protocol contracts first. Then scoped reads, evidence storage, and the effect boundary can progress independently against those contracts. Execution consumes packets and receipts; accretion consumes evidence, observations, and outcomes. Surface work consumes the resulting states. The integration owner serializes changes to shared Hoon state/action gates; a dependency graph is not permission for uncoordinated edits to the same file.

### Cutover rules

- Seer is pre-release: keep one current state definition and no migration chain. Explicitly nuke and revive the development agent when its state shape changes, discarding its state and subscriptions. Same-shape reloads preserve state. Introduce a migration strategy before official release, not during this development cutover.
- Add contract-version negotiation to the existing alignment canary. Tool-name coverage alone cannot establish schema or semantic compatibility.
- Update MCP definitions, prompt text, bridge callers, browser routes, and documentation together. Remove obsolete direct planner writes; no compatibility aliases that bypass the new authority boundary.
- Unsupported clients fail before writing and receive reimport/upgrade instructions. Do not guess schema compatibility or auto-fallback to a less constrained tool.
- Update README claims only as behaviors actually ship. Do not edit the archived 2021 plan into a competing roadmap.

### Observable acceptance scenarios

| Scenario | Required evidence |
| --- | --- |
| Cold start or resumed session | One bounded orientation response and targeted expansion identify goal, scope, evidence gaps, legal action, and existing work without loading a transcript. |
| Large library with unchanged history | Wire bytes and selected-read work stay within advertised bounds; no hidden whole-state serialization or repeated source bodies. |
| Missing, listing-only, stale, contradictory, or over-budget source | Distinct coverage/reason fields; no unsupported claim of a complete read. Unicode inputs obey byte limits. |
| Source refresh, archive, purge, or permission revocation during work | Old packet remains historically interpretable or explicitly unavailable; new dispatch respects current permission and cache invalidation. |
| New stack plus cards, invalid batch, concurrent edit, or A→B→A content change | Preview/commit agreement at matching revisions; otherwise zero partial effects and a precise conflict. |
| Duplicate command or lost commit response | One committed effect, one authoritative receipt, deterministic replay or reconciliation; retired epochs reject replay. |
| Two bridges, expired lease, rotation, cancellation, or crash at each execution boundary | Live ownership is not stolen; stale completions fail; uncertain external execution is not silently repeated. |
| Provider unavailable, output overflow, exhausted budget, or unknown usage | Named blocker/limit; no silent escalation, fabricated zero cost, or successful truncated answer. |
| Repeated capture, rejected proposal, misleading model output, or changing review performance | Evidence-linked reuse without duplicate learning work, truth laundering, inferred approval, or fabricated grades. |
| Browser/MCP inspection and approval | Equivalent non-secret state; exact diff and disclosure visible; keyboard, compact layout, and native-form fallback work. |
| Pre-release state reset, old clients, and mixed desk/MCP/bridge versions | Explicit nuke/revive starts clean; same-shape reloads preserve state; protocol checks reject unsafe writes before any effect. |

Use the existing [Hoon tests](desk/tests/seer.hoon), [bridge boundary tests](bridge/seer-ai-bridge.test.mjs), and [live alignment canary](bridge/check-ship-alignment.mjs), plus actual browser and installed-ship scenarios. Retain regression tests for plausible boundary failures, not tests that pin wording or merely echo submitted fields.

Record a baseline before implementing resource optimizations: calls and UTF-8 bytes to orient/resume, bytes and selected rows read per focused task, provider invocations and available usage, context/output bounds, recovery outcomes, and retained bytes. Compare small and large libraries with the same selected task. A resource improvement passes only if evidence coverage, authority, and observable learning behavior are preserved; do not invent a percentage target without a baseline.
