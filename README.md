# Seer

Seer is a spaced-repetition application for Urbit. It stores local stacks, pulls snapshots of stacks shared by other ships, and copies them into local stacks.

The browser interface uses server-rendered Hoon and HTMX 2.0.2. Seer has no React build, JavaScript bundle, or client-side state store. The review page adds one inline script for keyboard review and session progress; every action still works without it.

## Compatibility

- Zuse 408
- `%seer` web agent
- Browser interface at `/apps/seer`
- Landscape tile that opens `/apps/seer`

The repository retains the historical `%seer-cli` source for reference. The CLI is not in `desk.bill` because its terminal renderer does not support Zuse 408.

## Install from source

Create and mount a desk from the ship Dojo:

```hoon
|new-desk %seer
|mount %seer
```

Seer imports libraries and marks from `pkg/base-dev`. Check out the compatible Urbit revision:

```bash
git clone https://github.com/urbit/urbit.git
git -C urbit checkout 5a187fededc4582a34fcd6055c67bb63e0917b94
```

Copy `base-dev` and the Seer desk into the mount:

```bash
rsync -a urbit/pkg/base-dev/ /path/to/pier/seer/
rsync -a desk/ /path/to/pier/seer/
```

Commit and install the desk:

```hoon
|commit %seer
|install our %seer
```

Open Seer:

```text
http://localhost:8080/apps/seer
```

Use the ship HTTP port if it is not `8080`.

## Develop Seer

After a change under `desk/`, copy the desk into the mount:

```bash
rsync -a desk/ /path/to/pier/seer/
```

Commit the revision:

```hoon
|commit %seer
```

Gall reloads an installed `%seer` agent. For the first installation, run `|install our %seer` after the commit.

## Web architecture

- `desk/app/seer/index.hoon` renders complete pages and HTMX fragments.
- `desk/app/seer.hoon` handles routes, form data, state changes, and persistent state.
- GET routes render the review queue, library, shared stacks, and stack details.
- POST routes send typed `%seer-action` values and then render the changed view.
- `hx-boost`, `hx-target`, `hx-select`, and `hx-swap` replace the `#seer-app` fragment.
- Each route also returns usable HTML when JavaScript is unavailable. Adding a non-Note context source is the exception: those forms need the inline script.
- The shared app shell adds Vim-style navigation: `j`/`k` move between targets and wrap through stack cards, `J`/`K` and `d`/`u` scroll, `gg`/`G` jump, `gr`/`gi`/`gl`/`gs` change sections, `za`/`zo`/`zc`/`zR`/`zM` control disclosures, `i` enters a focused form, `ga` opens the assistant, and `?` opens the shortcut guide.
- Review adds `space` to flip, `1`–`4` to grade, a session progress bar, and disclosure state that survives fragment swaps.

The server owns the HTML and application state. Form fields decode into typed actions.

## AI and MCP

Seer publishes MCP tool definitions at `/x/mcp/tools` and prompt definitions at `/x/mcp/prompts`. The `%mcp` desk provides the HTTP transport. MCP clients use the same Seer tool definitions.

### Connect an MCP client

Install the `%seer` and `%mcp` desks. Then connect the client to the ship MCP endpoint:

```text
endpoint: http://<ship-host>:<http-port>/mcp
header:   Cookie: urbauth-~<ship>=<login-code>
tool:     mcp/import-mcp-tools {"desk":"seer"}
```

Import the tools again after a Seer upgrade. `%mcp-server` sends `tools/list_changed` when imported definitions change.

### Attach durable assistant context

Stack and card context lives in `%seer` state and survives browser, bridge, and
provider restarts. Stack context is available to every card in that stack; card
context stays scoped to one card. Every prompt shows the ready sources selected
by default, and each source can be excluded for that individual request.

The browser accepts four source kinds:

- **Note** — pasted facts, constraints, examples, or background.
- **Ship file** — a text-compatible file at a mounted Clay path.
- **Local file** — a browser-selected text file up to 128 KB.
- **Web page** — a public HTTP or HTTPS page fetched by the paired bridge.

Notes, local files, and Clay files are stored immediately. Web sources enter a
durable queue; the bridge rejects private-network destinations, follows only
validated redirects, extracts bounded readable text, and writes the normalized
snapshot back to `%seer`. Removing a source archives it from future prompts
without breaking the context snapshot selected by an already-queued request.
Every bridge claim, completion, and failure requires a fresh nonce-bound HMAC
proof covering the source ID, worker, nonce, and every mutable field. Gall
verifies and consumes the nonce in the same event that changes context state.
On startup, the paired bridge uses the same proof boundary to requeue any
source left `%working` by a crash before normal polling resumes.

### Create cards from a source

Seer stores each capture on the ship. Different MCP clients can inspect and continue the same capture.

Use this workflow:

1. Read the library, open captures, and target stack.
2. Open a named capture.
3. Stage each card proposal with a source and reason.
4. Review each proposal in `/apps/seer/inbox`.
5. Approve or reject the proposal.
6. Study approved cards in the review queue.

Approval creates the card and adds it to the review queue. The card retains its capture, source, reason, creator, and approval time.

The planning tools cannot approve a proposal. Seer applies an approval only after a person selects it in the browser.

### MCP tools

Seer publishes 35 tools:

| Tool | Purpose |
| --- | --- |
| `seer/list-stacks` | Lists stack IDs, titles, card counts, and review counts. |
| `seer/get-stack` | Returns the clean text for all cards in one stack. |
| `seer/list-captures` | Lists captures and their staged proposals. |
| `seer/learning-context` | Returns card content, review state, and source records. |
| `seer/create-stack` | Creates one local stack. |
| `seer/begin-capture` | Starts a capture that another MCP client can continue. |
| `seer/stage-card` | Adds one card proposal to the inbox. |
| `seer/add-card` | Creates and queues one card without inbox approval. |
| `seer/list-assistant-models` | Lists models that use signed-in local accounts. |
| `seer/clear-assistant-models` | Clears the model catalog before a bridge refresh. |
| `seer/register-assistant-model` | Registers one provider and model profile. |
| `seer/list-context-sources` | Lists durable stack/card sources and pending web ingestion jobs. |
| `seer/claim-context-source` | Claims one pending web source with a nonce-bound bridge proof. |
| `seer/recover-context-source` | Requeues an orphaned working source with a proof covering its previous worker. |
| `seer/finish-context-source` | Persists content only when the proof covers its complete label and text. |
| `seer/fail-context-source` | Stores a retryable error only when the proof covers that exact error. |
| `seer/list-card-questions` | Lists card questions, edit requests, and results. |
| `seer/claim-card-question` | Assigns one pending card request to a bridge worker. |
| `seer/answer-card-question` | Stores the answer for a claimed card question. |
| `seer/apply-card-edit` | Updates an owned card from a claimed edit request. |
| `seer/fail-card-question` | Stores a card request error for display and retry. |
| `seer/state-context` | Returns a planning snapshot of the local library. |
| `seer/list-change-requests` | Lists library plans and implementation briefs. |
| `seer/request-change` | Adds a library or desk change request to the queue. |
| `seer/claim-change` | Assigns one pending change request to a bridge worker. |
| `seer/stage-change-operation` | Adds one typed operation to a library plan. |
| `seer/finish-change` | Submits a plan or brief for browser review. |
| `seer/fail-change` | Stores a change request error for display and retry. |
| `seer/list-login-requests` | Lists provider sign-in requests queued from the browser. |
| `seer/issue-bridge-nonce` | Issues a short-lived nonce for one signed bridge mutation. |
| `seer/claim-login` | Assigns one pending sign-in request to a bridge worker. |
| `seer/post-login-challenge` | Publishes the verification URL and user code for a claimed sign-in. |
| `seer/finish-login` | Marks a claimed sign-in complete and clears its codes. |
| `seer/fail-login` | Stores a sign-in error for display and retry. |
| `seer/consume-login-code` | Atomically reads and clears a paste-back code for the authenticated bridge. |

Write tools are safe to repeat with identical input. Seer returns `already-exists` and does not change state.

Seer rejects an existing ID if the new content differs. Each tool returns structured JSON.

### MCP prompt

Seer publishes the `seer/learn-anything` prompt. The prompt tells a client to inspect existing knowledge and stage 5 to 12 cards from named sources.

Claude Code exposes imported MCP prompts as commands. Codex can use the same workflow through the Seer tool descriptions.

### Codex configuration

Add the server to `~/.codex/config.toml`:

```toml
[mcp_servers.littel-wolfur]
enabled = true
url = "http://127.0.0.1:8080/mcp"
env_http_headers = { "Cookie" = "URBIT_MCP_COOKIE" }
```

### Claude Code configuration

Use user configuration or a project `.mcp.json`:

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

Set `URBIT_MCP_COOKIE` to the complete authenticated Cookie header. Keep the value in user configuration or the process environment.

Do not store the Cookie header in the repository. You can also run `claude mcp add --transport http --scope user` with the same URL and header.

After a Seer upgrade, import both definitions again:

```text
mcp/import-mcp-tools   {"desk":"seer"}
mcp/import-mcp-prompts {"desk":"seer"}
```

The MCP definitions are in `desk/lib/seer-mcp.hoon`. Tool threads use typed Gall pokes for changes and scries for reads.

## Request a Seer change

The inbox accepts change requests for **My library** and **Seer itself**.

A library request can use these operations:

- Create, rename, or delete a stack.
- Create, edit, or delete a card.
- Add a card to the review queue.

The bridge reads a library snapshot and asks the selected model for typed operations. Seer validates the operations before it stores the plan.

Each edit or deletion includes the values that the model read. Seer compares those values with current state during approval.

Approval fails if the target changed. A failed approval does not change the library.

A request for **Seer itself** produces an implementation brief. The brief covers the interface, state, actions, MCP contract, migration, security, tests, and acceptance criteria.

The request cannot generate or apply a desk patch. A developer must inspect the repository and implement the brief.

## Card assistant

Each card has an **Assistant** panel. Use **Ask** to request an explanation.

Use **Edit** to revise an owned card. Subscribed cards support **Ask** only.

Select a model with one of these OMP roles:

- **Fast** uses the `smol` role.
- **Balanced** uses the `default` role.
- **Deep** uses the `slow` role.

Each option shows its full OMP selector, such as `openai-codex/gpt-5.6-terra`. Seer stores the selected profile with the request.

An edit response must contain the complete title, front, back, and edit summary. Seer applies all fields in one state change.

Seer rejects the edit if the card changed after the request. The assistant history retains the previous and current values.

### Run the local bridge

Seer does not store OpenAI or Anthropic credentials. The local bridge uses existing Codex and Claude Code logins.

The bridge performs these tasks:

1. Check each local CLI login.
2. Publish available model profiles to Seer.
3. Claim pending card and change requests.
4. Run the selected provider.
5. Return the result through authenticated MCP tools.

The bridge discovers Codex models with `codex debug models`. It publishes the configured Claude models only when Claude Code reports a valid login.

The selected model and OMP role control the provider model and reasoning effort. Each provider receives one prompt and no tools.

The bridge removes `OPENAI_API_KEY` and `ANTHROPIC_API_KEY` from the child environment. This prevents an API key from replacing the selected account login.

Card text is untrusted context. Provider prompts tell the model not to follow instructions in a card.

Failed requests stay in Seer. Fix the local login, then select **Try again**.
After the paired bridge is running, open **Inbox** or any card's Assistant
panel. Seer shows provider-specific **Sign in** controls when an account is
unavailable. Codex uses device authorization; Claude Code opens its persistent
subscription login and accepts the one-time paste-back code in Seer. Inbox also
shows connected providers and offers **Sign out**.

Terminal login remains available as a recovery path on the bridge host:

```bash
codex login --device-auth
codex login status
claude auth login --claudeai
claude auth status
```

On NixOS, install Claude Code from nixpkgs:

```bash
NIXPKGS_ALLOW_UNFREE=1 nix profile install --impure nixpkgs#claude-code
```

Copy `bridge/ai-bridge.example.json` to `~/.config/seer/ai-bridge.json`. Set a command path only when the command is not on `PATH`.
`mcpTimeoutMs` bounds each bridge-to-ship call (default 30000).
`contextMaxBytes` bounds each fetched source (default 131072), and
`contextFetchTimeoutMs` bounds each fetch (default 20000).

Pair the bridge with Seer before enabling frontend sign-in. Generate a
high-entropy shared secret on the bridge host:

```bash
openssl rand -hex 32
```

Copy the output into the local ship Dojo and the bridge configuration:

```hoon
&noun [%set-bridge-capability 'PASTE_THE_GENERATED_VALUE']
```

Set the same value as `bridgeSecret` in `~/.config/seer/ai-bridge.json`, or
export it as `SEER_BRIDGE_SECRET`. The secret is separate from the ship MCP
cookie and never crosses MCP. Before each protected mutation, Seer issues a
short-lived nonce; the bridge sends an HMAC-SHA256 proof covering the action,
request, worker, nonce, and every mutable field. Seer atomically consumes valid
nonces and rejects expired or replayed proofs. General login listings never
return paste-back codes; the signed one-shot consume tool reads and clears one.
Repeat the local Dojo poke with a new value to rotate the secret and clear
outstanding nonces.

Start the bridge:

```bash
node bridge/seer-ai-bridge.mjs
```

The bridge reads the Cookie header from `~/.codex/config.toml` by default. You can also set `SEER_MCP_COOKIE`.

Use `bridge/seer-ai-bridge.service` to run the bridge as a user systemd service.

Run the bridge tests:

```bash
node --test bridge/seer-ai-bridge.test.mjs
```

After a Seer upgrade, import the tools again:

```text
mcp/import-mcp-tools {"desk":"seer"}
```
