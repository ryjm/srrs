# Seer

Seer is a spaced-repetition system that runs as an Urbit Gall agent. It can
create and review local stacks, subscribe to stacks from other ships, and copy
shared stacks into the local library.

The browser interface is fully server-rendered Hoon. HTMX 2.0.2 is the only
client-side runtime: there is no React build, Node dependency, generated
JavaScript bundle, or client-side state store. Links and forms replace the
`#seer-app` fragment, while the same endpoints remain usable as normal HTML.

## Current compatibility

- Zuse 408
- `%seer` web agent
- Browser UI at `/apps/seer`
- Landscape tile linking directly to `/apps/seer`
- The historical `%seer-cli` source remains in the repository for reference,
  but is not in `desk.bill`; its old JSON terminal renderer is not compatible
  with Zuse 408.

## Install from source

Create and mount a desk from your ship's Dojo:

```hoon
|new-desk %seer
|mount %seer
```

Seer imports libraries and marks supplied by `pkg/base-dev`. Overlay a Zuse-408
base-dev desk, then this repository's desk, onto the new mount:

```bash
git clone https://github.com/urbit/urbit.git
git -C urbit checkout 5a187fededc4582a34fcd6055c67bb63e0917b94
rsync -a urbit/pkg/base-dev/ /path/to/pier/seer/
rsync -a desk/ /path/to/pier/seer/
```

Commit and install it:

```hoon
|commit %seer
|install our %seer
```

Then open:

```text
http://localhost:8080/apps/seer
```

Use your ship's actual HTTP port when it differs from `8080`.

## Development

After editing files under `desk/`, copy them into the mounted desk and commit:

```bash
rsync -a desk/ /path/to/pier/seer/
```

```hoon
|commit %seer
```

If `%seer` is already installed, Gall reloads it from the new desk revision.
For a first installation, run `|install our %seer` after the commit.

## Web architecture

- `desk/app/seer/index.hoon` renders documents and HTMX fragments.
- `desk/app/seer.hoon` owns routing, form decoding, actions, and state.
- GET routes render review, owned-stack, shared-stack, and stack views.
- POST routes apply typed `%seer-action` state transitions, then render the
  updated target view.
- `hx-boost`, `hx-target`, `hx-select`, and `hx-swap` keep navigation and forms
  incremental without making the server API depend on JavaScript.

The response and routing structure follows the Hoon/HTMX approach used by
Hawk: HTML is authoritative on the server, form fields decode into typed
actions, and each response contains a complete usable view.

## AI and MCP

Seer is a self-describing MCP application. It owns its learning semantics and
publishes a typed capability manifest from its Gall agent at
`/x/mcp/tools`. The `%mcp` desk remains the authenticated transport and tool
registry. This split keeps Seer independent of any AI vendor or CLI while
making its capabilities discoverable by every MCP-compatible client.

After installing both desks, connect the AI client to the ship's authenticated
MCP endpoint and import Seer's tools once:

```text
endpoint: http://<ship-host>:<http-port>/mcp
header:   Cookie: urbauth-~<ship>=<login-code>
tool:     mcp/import-mcp-tools {"desk":"seer"}
```

Re-run the import after a Seer upgrade to refresh its contract. `%mcp-server`
emits a `tools/list_changed` notification when the imported definitions change.

Seer publishes a vendor-neutral learning loop, not just a card-writing API.
Capture state lives on the ship, so a session started in Codex can be inspected
or continued in Claude without copying a transcript between them:

1. The AI reads the library, open captures, and the target stack's learning
   context.
2. It opens a named capture and stages source-grounded card proposals.
3. Seer's HTMX inbox shows the prompt, answer, rationale, source, and creator.
4. A person approves or rejects each proposal. Only approval creates a card and
   puts it into spaced repetition.
5. Approved cards retain their capture, source, rationale, creator, and approval
   timestamps. Future agents receive that provenance alongside the scheduling
   state, so they can extend weak areas instead of generating generic repeats.

The AI-facing planning contract has no apply capability. A model may describe
an edit or deletion, but the human gate belongs to `%seer`, not to whichever
model happened to draft the material.

Seer currently publishes twenty-three tools:

| Tool | Purpose |
| --- | --- |
| `seer/list-stacks` | Read compact stack and review counts before choosing where knowledge belongs. |
| `seer/get-stack` | Read clean card content without Seer's internal front matter. |
| `seer/list-captures` | Find open and completed ship-resident capture sessions, including staged proposals. |
| `seer/learning-context` | Read cards with recall scheduling signals and source provenance. |
| `seer/create-stack` | Create a local stack without overwriting an existing taxonomy. |
| `seer/begin-capture` | Open a durable learning session that any MCP client can resume. |
| `seer/stage-card` | Put a source-grounded proposal in the human inbox without queuing it. |
| `seer/add-card` | Explicitly bypass the inbox and immediately queue a card when the user asks. |
| `seer/list-assistant-models` | Read the credential-backed OMP model catalog currently available on this machine. |
| `seer/clear-assistant-models` | Clear stale catalog entries before the local bridge publishes a fresh snapshot. |
| `seer/register-assistant-model` | Publish one exact provider/model selector under an OMP role. |
| `seer/list-card-questions` | Read durable in-card questions, provider state, and answer history. |
| `seer/claim-card-question` | Atomically claim a pending question for one local bridge worker. |
| `seer/answer-card-question` | Complete a claimed question without allowing another worker to overwrite it. |
| `seer/apply-card-edit` | Atomically revise an owned card from a claimed edit job while preserving its original snapshot. |
| `seer/fail-card-question` | Surface a provider or login failure safely in the card UI. |
| `seer/state-context` | Read one clean, immutable planning snapshot of every local stack and card. |
| `seer/list-change-requests` | Read durable library plans and Seer functionality briefs across clients. |
| `seer/request-change` | Let Codex or Claude enqueue the same generic approval-gated prompt workflow as the browser. |
| `seer/claim-change` | Atomically claim one pending prompt-driven planning job. |
| `seer/stage-change-operation` | Stage one typed library operation without mutating the library. |
| `seer/finish-change` | Publish a complete plan or implementation brief into the human review queue. |
| `seer/fail-change` | Preserve a safe planning failure for retry or rejection. |

Writes are additive and retry-safe. Repeating an identical request returns
`already-exists` without changing state; reusing an ID with different content
returns a conflict error. Every result is structured JSON.

Seer also publishes the MCP prompt `seer/learn-anything`. Prompt-aware clients
receive a complete capture recipe: inspect existing knowledge, identify gaps,
stage 5–12 atomic cards from named sources, and hand the result to the human
inbox. Claude Code exposes imported MCP prompts as commands; in Codex, the same
workflow is available directly from Seer's tool descriptions and ship-resident
state.

### Codex and Claude Code

Codex uses `~/.codex/config.toml`:

```toml
[mcp_servers.littel-wolfur]
enabled = true
url = "http://127.0.0.1:8080/mcp"
env_http_headers = { "Cookie" = "URBIT_MCP_COOKIE" }
```

Claude Code can use either user-scoped configuration or a project `.mcp.json`:

```json
{
  "mcpServers": {
    "littel-wolfur": {
      "type": "http",
      "url": "http://127.0.0.1:8080/mcp",
      "headers": { "Cookie": "${URBIT_MCP_COOKIE}" }
    }
  }
}
```

Set `URBIT_MCP_COOKIE` to the complete authenticated Cookie header value before
starting either client. Keep that value in user configuration or the process
environment, never in the repository. Claude Code may also add the server with
`claude mcp add --transport http --scope user`; use the same URL and header.

After upgrading Seer, refresh both nouns in `%mcp`:

```text
mcp/import-mcp-tools   {"desk":"seer"}
mcp/import-mcp-prompts {"desk":"seer"}
```

The implementation lives in `desk/lib/seer-mcp.hoon`. The agent only exposes
the manifests; imported tool threads interact with `%seer` through typed Gall
pokes and read-only scries. The inbox is at `/apps/seer/inbox`.

## Change Seer

The Inbox includes a global prompt surface for changing either **My library**
or **Seer itself**. Library prompts compile into a deliberately small
capability language: create, rename, or delete a stack; create, edit, or delete
a card; and queue a card for review.

The local bridge reads a clean state snapshot, asks the selected exact OMP
model for structured operations, validates the response, and stages it in
`%seer`. Every edit and deletion includes the title/front/back values the model
observed. Approval rechecks every snapshot and the coherence of the whole plan
before applying any operation; stale, duplicate, or structurally conflicting
plans fail without changing the library. Planning and application are separate
durable state transitions, so another browser or AI client can inspect the
same request.

The **Seer itself** target uses the same queue but intentionally produces an
implementation brief rather than an executable patch. The brief records the
desired UX, schema and action changes, MCP contract, migration, safety model,
tests, and acceptance criteria. This creates a durable runway toward reviewed
self-evolution while keeping arbitrary noun/code generation outside the
trusted mutation path. A future patch executor can consume that artifact under
an exact Clay base revision, isolated build checks, rollback metadata, and a
second explicit human apply gate.

## Card assistant

Every card in the library and review session has an **Assistant panel**. Choose
**Ask** for a grounded explanation or **Edit** to have the agent revise an owned
card, then choose an exact model through the OMP roles **Fast** (`smol`),
**Balanced** (`default`), or **Deep** (`slow`). Each option includes the concrete
OMP selector, such as `openai-codex/gpt-5.6-terra`. Requests snapshot that
profile, so retries continue using the same model even after the live catalog
changes. Results live in `%seer` state, appear on every device viewing the
planet, and can become context for later requests on the same card.

Edits use the same durable claim/worker queue as questions. The provider must
return a complete structured title, front, back, and edit summary. `%seer`
applies those fields atomically only if the card still matches the snapshot the
agent received; a newer human or assistant edit wins instead of being silently
overwritten. The Assistant panel keeps a before/after record after the current
card is updated. Remote subscribed cards remain ask-only until copied locally.

Seer deliberately does not store an OpenAI or Anthropic credential. The local
bridge in `bridge/seer-ai-bridge.mjs` verifies each CLI login, publishes only
models backed by a usable local account, and refreshes that catalog periodically.
It discovers the current Codex catalog from `codex debug models`; Claude's
current pinned model family is published only while Claude Code reports a valid
login. The bridge then polls the question queue through the same authenticated
MCP endpoint and invokes either:

- `codex exec`, using the existing `codex login` ChatGPT session; or
- `claude -p`, using the existing Claude Code / Claude.ai login.

The selected model and OMP role set both the CLI `--model` value and provider
reasoning effort (`low`, `medium`, or `high`). The provider gets an isolated,
one-turn tutor prompt with no write permission.
The bridge removes `OPENAI_API_KEY` and `ANTHROPIC_API_KEY` from the child
environment so a configured API key cannot silently replace the requested
subscription login. Card content is treated as untrusted context rather than
instructions. Failed jobs expose **Try again** and **Dismiss** controls in Seer.

Authenticate each local CLI once as the desktop user who runs the bridge:

```bash
codex login
codex login status
claude auth login
claude auth status
```

On NixOS, install Claude Code from nixpkgs rather than Anthropic's generic
native installer:

```bash
NIXPKGS_ALLOW_UNFREE=1 nix profile install --impure nixpkgs#claude-code
```

Provider failures do not lose the question. They are recorded in `%seer` and
can be retried after fixing the local login.

Copy `bridge/ai-bridge.example.json` to
`~/.config/seer/ai-bridge.json`, set executable paths when they are not on
`PATH`, and start the bridge:

```bash
node bridge/seer-ai-bridge.mjs
```

By default it reads the Urbit Cookie header for the configured MCP URL from
`~/.codex/config.toml`; `SEER_MCP_COOKIE` is also supported. The example
`bridge/seer-ai-bridge.service` can be installed as a user systemd service for
automatic startup. Run its dependency-free tests with:

```bash
node --test bridge/seer-ai-bridge.test.mjs
```

After upgrading, refresh Seer's tools in `%mcp` so the bridge operations are
available:

```text
mcp/import-mcp-tools {"desk":"seer"}
```
