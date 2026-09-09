# Seer: an agent-legible learning system

**Status: design baseline for the ship-native provider cutover (schema 3).** The schema-2 system shipped under Beads epic `srrs-login-epic-lyy`; this revision replaces the local bridge with provider clients inside `%seer` and moves provider accounts onto the ship. Beads epic `srrs-login-epic-d5n` tracks delivery; its ten slices shipped on 2026-09-09 and two live-verification tasks remain. [README.md](README.md) documents the implemented protocol and runtime limitations and changes only as behaviors ship; installed tool definitions and source settle current behavior. Never call a tool that the installed desk does not advertise.

## Purpose and design decision

Seer turns source material into a person's durable, correct understanding. Cards, captures, assistant requests, context sources, and review schedules are different stages of that process, not independent products. The agent's job is to help the person learn the right thing, not to maximize generated cards, provider calls, or autonomous activity.

The central design decision is to make three contracts fit together:

1. **Knowledge:** what was observed, from which exact evidence, with what coverage and uncertainty?
2. **Control:** which typed change is permitted, against which state, under whose authority?
3. **Proof:** what actually happened, how can it be reconciled, and what is safe to reuse?

Optimize in this order: authority and correctness; useful learning outcomes; recoverability and legibility; then latency, context, compute, and storage. A cheap answer based on silently omitted evidence is not an optimization. An explicit evidence gap or a decision to make no new cards can be a successful result.

The system should get easier to operate as it accumulates supported knowledge, not harder as it accumulates transcripts. It must remain usable with a fresh agent session, a small context window, an unavailable provider, an expired sign-in, or no network at all.

## Pre-cutover baseline

This inventory describes commit `3d3f96b` (schema 2, bridge-based execution), before implementation of this revision. The earlier schema-2 baseline and its consequences are in git history at `d1f8093c`.

| Existing mechanism | Consequence for this design |
| --- | --- |
| `%seer` owns state, receipts, evidence, packets, plan validation, learning artifacts, and 48 MCP tool definitions; the agent issues no outbound HTTP. | Keep every ship-side contract. Add outbound requests (Iris) and Behn deadlines to the agent; do not add a second truth store. |
| A Node bridge on the operator's computer polls four leased work queues (question, change, context, login) through MCP, signs mutations with nonce-bound HMAC proofs, supervises provider CLIs and login children, fetches web sources, and publishes the model catalog. | Remove the bridge, the paired-worker role, its 21 worker tools, the secret/nonce/lease/proof machinery, the systemd units, and the recovery CLI. Execution becomes ship events; the wire of each outbound request is the fence. |
| Provider generation is fenced for every provider and version: `inspectProvider` never returns `supported` and `runProvider` always throws `PROVIDER_UNSUPPORTED`, because neither CLI can guarantee a no-tools, no-hooks envelope. | Call provider HTTP APIs directly. A request body that carries no `tools` field is the no-tools envelope; no CLI, hooks, or configuration participate. |
| Sign-in runs the official CLIs on the bridge host; credentials stay in `~/.codex/auth.json` and `~/.claude/.credentials.json`; the ship stores only the public challenge. | Run the OAuth device (Codex) and paste-back PKCE (Claude) flows from the ship and store the resulting tokens in agent state. This is a deliberate reversal of the schema-2 rule that provider credentials never reach the ship. |
| Login records have no expired state, and any failure after a provider child started is `OUTCOME_UNKNOWN` (beads `srrs-login-epic-tq2`, `srrs-login-epic-5bp`). | The ship owns every sign-in deadline and classifies provider error bodies into named failures. |
| The bridge selects stacks/cards for library plans through bounded MCP pages (98,304 bytes, 40 calls, 6 stacks, 24 cards, 8 per stack) and freezes a `read_report`. | The packet builder selects from state directly under the same limits and records omissions; `read_report` and `remote-read-only` disappear as separate concepts. |
| Web sources enter a durable queue that only the bridge drains, with DNS-pinned private-network rejection and redirect revalidation. | The ship fetches web sources itself. Hostname-level policy and byte/deadline caps move into Hoon; DNS-level rebinding checks are unavailable to the agent and are documented as an accepted residual risk. |
| The Claude catalog is four hardcoded profiles; the Codex catalog is discovered through `codex debug models`. | Discover both catalogs over HTTP where the account allows it; a fixed list is labelled fixed. |
| The `dbug` agent wrapper exposes complete state at `/x/dbug/state`; `mcp/scry-agent` can read any exposed scry. | With credentials in state, every state peek must redact accounts. Replace the wrapper or filter its peek. |
| Plan-created cards receive no provenance; capture-approved cards do. | Plan commits must record change-plan provenance (this design already required it). |
| Snapshot (4,096), packet (2,048), learning-artifact (4,096), and context-source (512) admission counters never decrease; purge and collection free bodies only. | Admission limits must follow live counts or reclaim slots; a lifetime ceiling contradicts retention by usefulness. |
| Orientation advertises `seer/cancel-work` and `seer/start-change`, which are not published tools; partial pages return empty `omissions`; an oversized first row is a bare `limit-exceeded`. | Discovery names only published tools; partial pages disclose their omissions; an unfit row returns a bounded summary. |
| `copy-stack` ignores `keep-learned`; `lookup-learning` accepts only scope/objective/provider; packet entries carry omission reasons but no inclusion rationale; unauthenticated `/apps/seer/*` returns 500; authenticated GET parsing has no crash catcher. | Close each as a bounded implementation slice; none changes a contract. |

Source locations: [domain types](desk/sur/seer.hoon), [agent state, action gates, routes](desk/app/seer.hoon), [MCP definitions](desk/lib/seer-mcp.hoon), [bounded reads](desk/lib/seer-read.hoon), [evidence and packets](desk/lib/seer-evidence.hoon), [plan validation](desk/lib/seer-effects.hoon), [learning artifacts](desk/lib/seer-learning.hoon), [server-rendered interface](desk/app/seer/index.hoon), and, until removal, [bridge execution](bridge/seer-ai-bridge.mjs). The reference implementation for ship-side OAuth renewal, credential routing, and Responses-API assembly is the `%harness` desk (`lib/harness-oauth.hoon`, `lib/harness-auth.hoon`, `lib/harness-provider.hoon`); Seer ports the semantics, not the files.

## The abstraction stack

Each layer consumes references and guarantees from the layer below. Higher layers may propose changes; they may not manufacture lower-layer facts or permissions.

| Layer | Canonical concepts | What the next layer may rely on |
| --- | --- | --- |
| Identity and authority | Ship ownership, typed references, incarnations, revisions, effective capabilities | An unambiguous subject and an enforceable permission boundary |
| Evidence | Source locator, immutable snapshot, excerpt, coverage, derivation | Exactly what was available, what was read, and what remains unknown |
| Learning state | Card content, provenance, local scheduling state, actual learner observations | What is being learned, separately from whether its claims are true |
| Deliberate work | Existing capture, question, change request, and ingestion job; goal and stopping condition | A bounded, resumable unit of intention with explicit inputs |
| Effects and proof | Typed proposal/operation, approval, precondition, committed receipt | What was proposed versus what changed, and why replay is safe or unsafe |
| Surfaces and adapters | Browser, MCP, ship-native provider client and source fetcher | Consistent views and actions over the same domain contracts |

The feedback path is **evidence → proposal → authorized card change → learner observation → better evidence selection or a new proposal**. It is not model output → accepted fact. This is a conceptual graph of typed links in existing nouns and maps, not a requirement for a graph database, generic workflow engine, or vector store.

## Contract vocabulary

### One owner for each fact

- `%seer` owns library state, selected evidence references, work state, approvals, effect receipts, provider accounts, and the lifecycle of every outbound request it issues.
- Clay or a remote publisher owns live source content. Seer owns the snapshot it actually retrieved, not a claim about the source's present contents.
- The Urbit runtime owns sockets, TLS, and DNS. Iris delivers progress, completion, or cancellation for a request the agent issued; the agent owns the deadline, byte bound, and the decision to cancel.
- A provider produces candidate text or typed proposals. It neither attests factual truth nor commits library state. It receives exactly the packet Seer shows, under the account the person signed in, with no tools.
- The person owns learning objectives, approval decisions, explicit editing grants, recall grades, and provider sign-in. An agent cannot grade on the person's behalf to improve its metrics, and a planner cannot sign in, sign out, or select an account.
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
| `work_ref`, `attempt`, `deadline` | Durable request identity, a particular execution, and the ship-time bound after which that execution is fenced |
| `operation_id`, `idempotency_epoch` | One caller intent within a server-advertised replay namespace |
| `receipt_ref` | An authoritative recorded outcome, not a tool's echo of its input |

Expose revision fields only with their documented domain. `last-modified`, source retrieval time, and model confidence are not substitutes for a content precondition. Deletion and absence require explicit existence/incarnation preconditions too.

### Shared protocol, not a universal action tool

Keep domain-specific tools. Add common envelopes and use one domain validator from browser and MCP paths. Required response information is:

- Identity, schema, effective scope, and observation revision.
- Bounded data plus `complete`, `next_cursor`, and omissions with reasons. A complete empty set differs from unknown, unavailable, unauthorized, or not loaded.
- References to legal next actions and their unmet prerequisites. Every referenced action names a published tool or a native operator route; discovery never advertises an unpublished name. Tool schemas come from discovery; do not repeat full schemas on every row. Suggestions are advisory, never grants of authority.
- Structured outcomes such as `ok`, `blocked`, `conflict`, `invalid`, `unauthorized`, `budget_exhausted`, and `outcome_unknown`; stable reason codes, affected references, and a valid recovery path accompany human-readable explanation.
- An effect disposition of `none`, `staged`, `committed`, or `unknown`. Never report `none` when a transport failure leaves a commit uncertain.

Authenticate before exposing object details. Error responses must not reveal private subjects to unauthorized callers. Validation rejects oversized fields and batches in the authoritative action gate; there is no other parser.

Capability discovery distinguishes planner operations from operator approval/admin operations, and publishes that map machine-readably (`capabilities.operations.{planner,operator}`). Read and mutation envelopes advertise `schema_version: 3` and `capabilities_revision: 3`; a schema-2 command is rejected in the action gate before any effect, and a schema-2 client is told to reimport. There is no paired-worker class: execution is the ship's own event processing, not a delegated principal. The server derives effective capabilities from authenticated authority and the actual entry point; an `actor` field is only attribution. Planner-facing tools do not expose approval, sign-in, sign-out, account selection, cancellation of running work, or catalog replacement. Local owner administration remains an explicit trusted boundary.

This interface boundary is not a sandbox for an agent given the owner's Dojo or HTTP session plus arbitrary request tools. Such a caller can act as the owner outside MCP. Do not describe the current ship-cookie connection as a least-privilege credential. Restricted planner delegation requires the MCP transport to attest a scoped principal; a tool argument cannot manufacture that identity. Until it is supported, label the connection `owner-trusted` and reject jobs requiring stronger isolation rather than silently downgrading them. Provider tokens, PKCE verifiers, and pasted authorization codes must remain outside provider context and outside every read surface.

## Observation and navigation

The proposed read-only **`seer/agent-context`** is the entry point. It returns a compact orientation, not the whole library:

- Ship identity, protocol/capability revisions, requested scope, signed-in providers with catalog freshness and renewal state (never token material), and published limits.
- Relevant learning objective, stack/card counts, due-review counts, open captures/requests, unresolved approvals, and recovery blockers, all as bounded summaries and references.
- Evidence availability/freshness/coverage and an explanation of what was omitted.
- Valid ways to expand the selected subject, continue existing work, or stop.

With no selected scope, return a bounded library index and open-work index. A recent selection is a navigation hint, never an implicit mutation target. Read-only discovery must work without a signed-in provider or network access.

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

Provider access and refresh tokens, PKCE verifiers, pasted authorization codes, ship cookies, and API keys live only in the account slots of agent state. They never appear in orientation, bounded reads, evidence packets, receipts, activity, retained diagnostic bodies, generated summaries, subscription facts, exports, or `dbug`-style state peeks; every scry of agent state redacts account slots before serialization. Sign-out clears the slots in one event; `|nuke` discards them with the rest of state. A poke that stores a token is part of the ship's event log like any other event; this is an accepted consequence of ship-owned accounts, not a leak to another party. Prompts carry only the packet: never an account identifier, token, or ship secret.

## Safe effects

### Authority follows intention

| Intention | Target authority and effect |
| --- | --- |
| Inspect, explain, compare, propose | Planner may read allowed scope and produce staged artifacts; no library mutation implied. |
| Capture cards or reorganize a library | Planner stages proposals/typed operations; the person reviews exact effects before commit. Remove planner-facing `add-card` and `create-stack` bypasses at cutover. |
| User explicitly chooses card **Edit** | The ship completes that one requested edit against the pinned card revision when the provider result validates. The grant does not permit another card, grading, sharing, or a library plan. |
| Fetch a source or run a provider job | The ship issues one bounded outbound request per admitted attempt, under the request's allowed destinations, deadline, and budget; a planner can create the request, only an operator can start it. |
| Approve, grade, publish, sign in, sign out, select an account, cancel running work, replace the catalog, clear history | Operator surface only; not planner or provider authority. |
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

## Provider accounts, outbound requests, and recovery

Everything that previously ran on the bridge runs as Gall events in `%seer`: sign-in, token renewal, provider generation, web source acquisition, and catalog discovery. There is no polling client, no worker identity, no lease, and no proof. An outbound request is a card; its wire names the work reference and attempt; the response event is authoritative only if that attempt is still the current one.

### Accounts and sign-in

State holds one account slot per provider: `[method access refresh account expires scopes observed-at renewal]`, where `method` is `%oauth`, `%setup-token`, or `%api-key`. Slots are written only by operator sign-in, renewal, and sign-out; a planner cannot create, read, or select one. The Settings page and the native `request-login`/`submit-login-code`/`cancel-login`/`request-logout` routes remain the only entry points. Each ship signs in separately; a moon and its planet do not share an account.

**Codex** uses the OAuth device flow with the public Codex client id (`app_EMoamEEZ73f0CkXaXp7hrann`), entirely from the ship. `request-login` issues `POST https://auth.openai.com/api/accounts/deviceauth/usercode`; the response yields the `%challenge` state (verification URL `https://auth.openai.com/codex/device`, `user_code`, poll interval, and a 15-minute deadline). A Behn timer polls `POST …/deviceauth/token` at the advertised interval; a pending answer re-arms the timer, an `authorization_code` plus `code_verifier` is exchanged at `POST https://auth.openai.com/oauth/token` (`grant_type=authorization_code`, `redirect_uri=https://auth.openai.com/deviceauth/callback`), and the ChatGPT account id is read from the `https://api.openai.com/auth` claim of the id token. The deadline, a `device authorization disabled` error body, a rejected code, and network failure are distinct named failures (`%expired`, `%device-auth-disabled`, `%denied`, `%unreachable`); the challenge page never shows a stale code past its deadline. No browser script participates; the challenge is server-rendered and polls only the account panel, as today.

**Claude** uses the paste-back PKCE flow of the official client (client id `9d1c250a-e61b-44d9-88ed-5944d1962f5e`). The ship generates a verifier and state from entropy, renders the authorize URL at `https://platform.claude.com/oauth/authorize` (`code=true`, `response_type=code`, `redirect_uri=https://platform.claude.com/oauth/code/callback`, `code_challenge_method=S256`, scopes `org:create_api_key user:profile user:inference`), and the person pastes the `code#state` shown by the callback page. `submit-login-code` verifies the state, exchanges the code at `POST https://platform.claude.com/v1/oauth/token` in the same event, and clears the pasted code and verifier whether or not the exchange succeeds. A pasted `claude setup-token` value or credential JSON is accepted as method `%setup-token` without an exchange. Provider requests send `Authorization: Bearer` with `anthropic-beta: oauth-2025-04-20`; if a provider rejects OAuth tokens outside its own client, the named failure says so and the API-key method remains available.

**API keys** are accepted for both providers as an explicit method with the provider's native key header. The method is part of the account slot and of the catalog observation; a key never silently substitutes for an OAuth session or the reverse.

**Renewal** happens at the transport boundary, on use, never by idle polling: before any request that needs an OAuth account, if the access token expires within five minutes and a refresh token exists, the request is held (bounded, 64 at most), one refresh is issued with a 30-second Behn deadline, and on success both tokens rotate in the same event that releases the held requests. A missing rotated refresh token keeps the previous one. `400`/`401`/`403` are terminal (`sign in again`); other failures set a one-minute cooldown. A slot rewritten by a new sign-in or sign-out fences every in-flight renewal and held request by identity. The raw token response is never retained or displayed. Claude renewal uses `grant_type=refresh_token` at the same token endpoint; setup tokens and API keys do not renew.

**Policy.** Both flows drive first-party client identities from third-party code, and provider terms may restrict that. Seer states the method it uses, keeps the API-key method as the policy-conservative alternative, and does not disguise its requests as the official client beyond the compatibility headers those APIs require (`originator`, `chatgpt-account-id`, `anthropic-beta`).

### Outbound requests

The ship issues each provider or fetch request as `%pass /seer/<kind>/<id>/<attempt> %arvo %i %request` with `outbound-config [redirects=0 retries=0]`, together with a Behn deadline on a matching wire. The response handler ignores any sign whose wire does not name the current attempt of a running record; a fired deadline cancels the request (`%cancel-request`) and fails the attempt as `%timeout`; a `%progress` sign whose `bytes-read` exceeds the attempt's output bound cancels the request and fails it as `%output-limit`. Redirects are handled by the agent, not the runtime: at most five, each re-validated by the same destination policy, so a private destination is rejected at every hop that the agent can see.

A provider request carries only the frozen packet's prompt and the selected model. Codex uses the Responses API at `https://chatgpt.com/backend-api/codex/responses` with `store: false`, `stream: true`, `instructions`, `input`, and **no `tools` field**; headers are `Authorization`, `chatgpt-account-id`, and the `originator`/`User-Agent` values the Codex client sends. The streamed `output_item.done` items are collected and a terminal `response.completed` (or an explicit failure event) is required; a completed item alone is not a completed response. Claude uses `POST https://api.anthropic.com/v1/messages` with `anthropic-version`, the account's authorization header, `max_tokens` from the output budget, `system`, `messages`, and **no `tools`**. The absence of tools, hooks, configuration, and shell is the no-tools envelope; there is nothing else to enforce. A provider that returns a tool call, an unexpected content type, or a non-JSON answer where the output schema requires JSON fails the attempt as `%invalid-output` with a bounded diagnostic; the raw body is not retained beyond that bound.

Structured results are validated in Hoon against output schema 2 before any effect: an answer is stored; an edit is applied under its prior grant and pinned revision; a library plan enters the same candidate-state validator as a planner-submitted plan and becomes `ready`; a desk brief is stored as prose. `usage` is recorded from the response (`input_tokens`, `output_tokens`, cached tokens where reported); cost stays `unknown`. Refusals, empty output, and stop reasons are recorded verbatim as stop reasons, never as answers.

### Execution records and recovery

Keep common execution metadata on runnable records; do not replace their domain state machines. Captures remain proposal containers, not jobs. Represent execution (`queued`, `running`, `blocked`, `succeeded`, `failed`, `cancelled`) separately from effect disposition (`none`, `staged`, `committed`, `unknown`). Execution metadata is `attempt`, `deadline`, checkpoint (`packet-frozen`, `request-issued`, `response-received`, `result-validated`, `receipt-recorded`), invocation count, consumed output bytes, `usage`, `cost`, and stop reason. Worker, lease, proof, and secret-revision fields do not exist.

Because a Gall event either completes or leaves no trace, the ambiguous crash window shrinks to one case: the request card was emitted and the response never arrives. A running attempt whose deadline fires is failed as `%timeout` with disposition `unknown` for provider work (the provider may have run) and `none` for fetches; the person decides whether to start a new attempt. An agent reload does not lose in-flight requests or timers, and `on-load` re-checks every running attempt's deadline against `now`. A response for a cancelled, superseded, or expired attempt is dropped by the wire check. Cancellation is an operator action on the record (Inbox, Activity, or Settings), issues `%cancel-request`, fences later signs, and cannot reverse an external side effect or charge.

Budgets are part of admission and survive reload: deadline, allowed provider/profile, maximum invocations, input/excerpt bytes, output bytes, operation count, and concurrent work. One provider request runs at a time per provider; up to two source fetches run concurrently; catalog refresh never displaces admitted work. Start with one provider invocation per admitted attempt and no automatic escalation. A different model, larger budget, or another attempt requires permission within the original grant or renewed authorization. Deterministic validation, filtering, and rendering never need a model. Cache derived work only by exact input revisions, scope/egress policy, prompt/schema version, and model/profile; check authority again before reuse. A missing account, terminal renewal failure, expired sign-in, or unavailable exact profile is a named blocker, not silent fallback.

### Source acquisition on the ship

Web sources are fetched by the agent under the same request discipline: destination policy, five agent-handled redirects, a 20-second deadline, and a 131,072-byte cap enforced from `%progress`. The destination policy admits only `http` and `https`, no userinfo, no IP literals of any family, no `localhost`, `.local`, `.internal`, `.onion`, or single-label hosts, ports 80 and 443 only, and URLs of at most 4,096 bytes. The runtime resolves names, so the agent cannot reject a public hostname that resolves to a private address; this DNS-level check existed on the bridge and is lost. It is recorded as an accepted risk of ship-native fetching and disclosed in the README, not compensated by a claim the agent cannot verify. Text extraction is deterministic Hoon: HTML/XML tag stripping with entity decoding, whitespace normalization, and UTF-8 validation with exact omitted ranges; the extraction method and version are part of the snapshot as before. Notes, local files, and Clay files are unchanged.

### Catalog discovery

After sign-in and on operator request, the ship reads the Codex catalog from `https://chatgpt.com/backend-api/codex/models` (with the `client_version` the current Codex client reports, a pinned compatibility value) and the Claude catalog from `https://api.anthropic.com/v1/models`; an account whose method cannot list models keeps an explicitly labelled fixed list. Catalog replacement is one state change with its own revision; roles (Fast, Balanced, Deep) map to exact model ids by operator choice, never by inference.

### Library plan preparation

For a change request, the packet builder selects context from state deterministically under the schema-2 limits (six stacks, 24 cards, eight per stack, 98,304 structured bytes) using normalized-token overlap between the prompt and stack/card titles, with stable reference order as the tie-break. Remote stacks are read-only and appear as omissions with reason `remote-read-only`; discovery, selection, and byte caps produce explicit omissions, never a claim of completeness. The frozen packet is the only input the provider sees.

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

“Ready for review,” “answer stored,” and “applied” are distinct labels and machine states. Missing evidence, no signed-in account, expired sign-in, renewal failure, stale plan, expired deadline, and unknown outcome each need a different recovery action. Settings shows each provider's method, account label, catalog freshness, renewal state, and named failure without token material; Inbox and Activity offer cancel and retry on the record itself. No page mentions a bridge. A disabled action explains the unmet precondition rather than forcing trial-and-error tool calls.

Browser and MCP views derive from the same records, validators, and packet builder. Approval shows the exact plan version and scope; a stale approval shows a new diff before another approval. Destructive effects and public disclosure are explicit, not buried in assistant prose. Compact layouts and keyboard navigation retain the same evidence and decision path with progressive disclosure; focus survives fragment changes. Accessibility and no-JS operation are interaction constraints, not a second business-logic implementation.

## Delivery and proof

### Durable implementation map

Beads is the source of task status, acceptance criteria, and dependency edges. This table maps contracts to implementation slices of the ship-native cutover epic `srrs-login-epic-d5n` (slice N is `srrs-login-epic-d5n.N`); it is not another task checklist.

| Slice | Contract owned |
| --- | --- |
| 1 | Schema-3 contracts: state shape (account slots, execution metadata without worker/lease/proof), action union without worker actions, MCP surface reduced to 27 planner/read tools with `capabilities_revision: 3`, machine-readable capability map, regenerated tool contract; [Contract vocabulary](#contract-vocabulary) |
| 2 | [Accounts, sign-in, renewal](#accounts-and-sign-in): Codex device flow, Claude paste-back PKCE and setup token, API keys, transport-boundary renewal, redacted state peeks, sign-out |
| 3 | [Outbound request discipline](#outbound-requests): Iris cards with attempt wires, Behn deadlines, `%progress` byte caps, agent-handled redirects, destination policy, cancellation |
| 4 | Provider generation for card questions and edits: Responses-API and Messages-API assembly, SSE parsing, output-schema validation, usage capture, effect application under the edit grant |
| 5 | [Library plan preparation](#library-plan-preparation) and desk briefs on the ship: deterministic selection from state, packet freezing, plan validation into `ready` |
| 6 | [Source acquisition on the ship](#source-acquisition-on-the-ship): web fetch, redirect policy, extraction, immediate dispatch replacing the bridge queue |
| 7 | [Catalog discovery](#catalog-discovery) and role mapping |
| 8 | [Surfaces](#human-and-agent-surfaces): Settings account panels with method/expiry/named failures, Inbox/Activity cancel and retry, expired challenge rendering, removal of bridge copy |
| 9 | Baseline gap closure that does not change contracts: plan-created provenance, live admission counts, published-only next actions, disclosed omissions on partial pages and oversized rows, `keep-learned`, lookup filters, packet inclusion reasons, unauthenticated redirect, GET crash catcher |
| 10 | Removal and verification: delete the bridge, its tests, units, installer, and config; move the alignment canary to a developer-only tool with the schema-3 contract; README and prompt updates as each slice ships; Hoon tests for every boundary above; nuke/revive and MCP reimport on the development moons |

The keyboard work `srrs-login-epic-0dj` and `srrs-anm` remains independently owned. Consult Beads for current status; completed evidence, receipt, plan, and sharing work is reused, not reopened under new names.

Establish the schema-3 contracts and state shape first (slice 1). Accounts (2) and request discipline (3) then progress independently against those contracts; generation (4), plans (5), fetching (6), and catalog (7) consume both; surfaces (8) consume the resulting states; gap closure (9) runs in parallel with everything except slice 1; removal (10) is last. The integration owner serializes changes to shared Hoon state/action gates; a dependency graph is not permission for uncoordinated edits to the same file.

### Cutover rules

- Seer is pre-release: keep one current state definition and no migration chain. Explicitly nuke and revive the development agent when its state shape changes, discarding its state, subscriptions, and accounts. Same-shape reloads preserve state. Introduce a migration strategy before official release, not during this development cutover.
- The alignment canary negotiates `capabilities_revision: 3` and rejects a catalogue that still lists any worker tool; tool-name coverage alone cannot establish schema or semantic compatibility. It is a developer verification tool, not a runtime component.
- Update MCP definitions, prompt text, browser routes, and documentation together. Remove worker tools, worker actions, nonce/secret state, and bridge copy in the same cutover; no compatibility aliases, no dormant worker path.
- Unsupported clients fail before writing and receive reimport/upgrade instructions. Do not guess schema compatibility or auto-fallback to a less constrained tool.
- Update README claims only as behaviors actually ship. Do not edit the archived 2021 plan into a competing roadmap.
- Stop and disable both bridge instances before installing a schema-3 desk; a schema-2 bridge against a schema-3 ship must fail at its first catalogue check, not at a mutation.

### Observable acceptance scenarios

| Scenario | Required evidence |
| --- | --- |
| Cold start or resumed session | One bounded orientation response and targeted expansion identify goal, scope, evidence gaps, legal action, and existing work without loading a transcript; every advertised next action is a published tool or native route. |
| Large library with unchanged history | Wire bytes and selected-read work stay within advertised bounds; no hidden whole-state serialization or repeated source bodies; partial pages disclose omissions. |
| Missing, listing-only, stale, contradictory, or over-budget source | Distinct coverage/reason fields; no unsupported claim of a complete read. Unicode inputs obey byte limits. |
| Source refresh, archive, purge, or permission revocation during work | Old packet remains historically interpretable or explicitly unavailable; new dispatch respects current permission and cache invalidation. |
| New stack plus cards, invalid batch, concurrent edit, or A→B→A content change | Preview/commit agreement at matching revisions; otherwise zero partial effects and a precise conflict; plan-created cards carry plan provenance. |
| Duplicate command or lost commit response | One committed effect, one authoritative receipt, deterministic replay or reconciliation; retired epochs reject replay. |
| Sign-in: device flow completes, expires, is disabled by the account, or is cancelled; Claude code pasted with wrong state; setup token or API key entered | Named state on Settings; no stale code past its deadline; tokens never rendered or readable; sign-out clears the slot; a planner cannot observe or trigger any of it. |
| Renewal: token near expiry, refresh rejected, refresh times out, sign-in replaced mid-renewal | Held requests release on one rotation or fail with one named reason; no duplicate refresh; stale responses fenced by identity; raw token bodies never retained. |
| Reload during an in-flight request, deadline fired, cancellation, late or duplicate response, output over bound | In-flight work survives reload; late/duplicate/superseded signs are dropped by the wire; timeout and overflow are named failures with correct disposition; uncertain external execution is not silently repeated. |
| Provider unavailable, tool call in output, non-JSON output, refusal, exhausted budget, or unknown usage | Named blocker/limit; no silent escalation, fabricated zero cost, or successful truncated answer; usage is recorded when reported. |
| Web fetch to a private literal, disallowed port, credentialed URL, redirect chain, oversized or slow body | Rejected at the agent with the exact reason; five redirects at most; cap and deadline enforced from progress signs. |
| Repeated capture, rejected proposal, misleading model output, or changing review performance | Evidence-linked reuse without duplicate learning work, truth laundering, inferred approval, or fabricated grades. |
| Browser/MCP inspection and approval | Equivalent non-secret state; exact diff and disclosure visible; keyboard, compact layout, and native-form fallback work. |
| Pre-release state reset, old clients, and mixed desk/MCP versions | Explicit nuke/revive starts clean; same-shape reloads preserve state; a schema-2 client or bridge fails at discovery, before any effect. |

Use the existing [Hoon tests](desk/tests/seer.hoon), new pure tests for the renewal reducer, destination policy, SSE and output parsers, and login state machine, the [alignment canary](bridge/check-ship-alignment.mjs) in its developer-tool location, plus actual browser and installed-ship scenarios. Retain regression tests for plausible boundary failures, not tests that pin wording or merely echo submitted fields.

Record a baseline before implementing resource optimizations: calls and UTF-8 bytes to orient/resume, bytes and selected rows read per focused task, provider invocations and available usage, context/output bounds, recovery outcomes, and retained bytes. Compare small and large libraries with the same selected task. A resource improvement passes only if evidence coverage, authority, and observable learning behavior are preserved; do not invent a percentage target without a baseline.
