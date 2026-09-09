# Project Instructions for AI Agents

This file provides instructions and context for AI coding agents working on this project.

<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:6cd5cc61 -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

**Architecture in one line:** issues live in a local Dolt DB; sync uses `refs/dolt/data` on your git remote; `.beads/issues.jsonl` is a passive export. See https://github.com/gastownhall/beads/blob/main/docs/SYNC_CONCEPTS.md for details and anti-patterns.

## Agent Context Profiles

The managed Beads block is task-tracking guidance, not permission to override repository, user, or orchestrator instructions.

- **Conservative (default)**: Use `bd` for task tracking. Do not run git commits, git pushes, or Dolt remote sync unless explicitly asked. At handoff, report changed files, validation, and suggested next commands.
- **Minimal**: Keep tool instruction files as pointers to `bd prime`; use the same conservative git policy unless active instructions say otherwise.
- **Team-maintainer**: Only when the repository explicitly opts in, agents may close beads, run quality gates, commit, and push as part of session close. A current "do not commit" or "do not push" instruction still wins.

## Session Completion

This protocol applies when ending a Beads implementation workflow. It is subordinate to explicit user, repository, and orchestrator instructions.

1. **File issues for remaining work** - Create beads for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **Handle git/sync by active profile**:
   ```bash
   # Conservative/minimal/default: report status and proposed commands; wait for approval.
   git status

   # Team-maintainer opt-in only, unless current instructions forbid it:
   git pull --rebase
   git push
   git status
   ```
5. **Hand off** - Summarize changes, validation, issue status, and any blocked sync/commit/push step

**Critical rules:**
- Explicit user or orchestrator instructions override this Beads block.
- Do not commit or push without clear authority from the active profile or the current user request.
- If a required sync or push is blocked, stop and report the exact command and error.
<!-- END BEADS INTEGRATION -->


## Build & Test

Seer is an Urbit desk under `desk/`; there is no build step. A development
ship mounts the desk and Clay compiles it on commit:

```bash
rsync -a desk/ /path/to/pier/seer/        # copy the desk into the mount
```

```hoon
|commit %seer                             # compile and reload the agent
-test /=seer=/tests ~                     # run the desk tests
```

The MCP alignment canary in `tools/` is plain Node (no dependencies):

```bash
node --test tools/check-ship-alignment.test.mjs                 # hermetic tests
SEER_MCP_URL=http://127.0.0.1:8080/mcp SEER_MCP_COOKIE='urbauth-~sampel=...' \
  node tools/check-ship-alignment.mjs                           # live ship check
```

Compiling `desk/app/seer.hoon` takes about 25 seconds on a dev ship; check one
file at a time rather than rebuilding everything after every edit.

## Architecture Overview

`%seer` (`desk/app/seer.hoon`) is a single Gall agent that owns library state,
review scheduling, evidence snapshots, work records, receipts, and provider
accounts. It serves a server-rendered HTMX interface (`desk/app/seer/index.hoon`)
whose POST routes decode into the same typed `action` union used everywhere
else; MCP tool and prompt definitions (`desk/lib/seer-mcp.hoon`) run as threads
that poke that union and scry bounded JSON reads (`desk/lib/seer-read.hoon`).
Provider sign-in, token renewal, generation, catalog discovery, and web source
fetching are ship-native: the agent issues Iris requests with attempt-scoped
wires and Behn deadlines (`desk/lib/seer-net.hoon`, `desk/lib/seer-oauth.hoon`),
so there is no external worker process. Types live in `desk/sur/seer.hoon`;
validators and packet builders in `desk/lib/seer.hoon`, `seer-evidence.hoon`,
`seer-effects.hoon`, and `seer-learning.hoon`.

## Conventions & Patterns

- Pre-release: keep exactly one state shape and no migration chain. When the
  shape changes, `|nuke %seer, =hard &`, `|commit %seer`, `|revive %seer` on the
  development ship, then reimport the MCP tools and prompts. Same-shape reloads
  keep state.
- Every mutation, from the browser or MCP, is a `command` with an epoch,
  operation id, and digest, and produces a receipt; do not add side doors.
- Tool names, parameters, and the orientation's capability fields are a
  contract: change `desk/lib/seer-mcp.hoon`, `tools/seer-tool-contract.json`,
  and the README together, then run the canary.
- Track work with `bd` (Beads); the current epic is `srrs-login-epic-d5n`.
- README claims describe shipped behavior only; SYSTEM_DESIGN.md holds the
  design rationale.
