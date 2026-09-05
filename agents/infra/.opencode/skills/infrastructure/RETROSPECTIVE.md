# RETROSPECTIVE — infrastructure skill

Stacked journal, newest entry first. One entry per change-task, with three sections — went well / went bad / improve. Record user-made changes too, and say who made what. A lesson promotes into `SKILL.md` when it recurred across 2+ tasks or changed behavior; mark promoted lessons in the entry they came from.

_Previous entries condensed into SKILL.md "Operational lessons" section on 2026-08-30. Start fresh below._

## 2026-09-03 — duc-monitor normalized schema

**Went well**
- Calculated expected savings before implementing (9× reduction).
- Implemented normalized schema: paths, timestamps, sizes with foreign keys.
- Auto-migration from old flat schema works seamlessly.
- Updated all three scripts (duc-parse, duc-viz, duc-clean) and server.
- Treemap renders correctly with JOIN queries.

**Went bad**
- Server's `list_hosts` and `list_scans` endpoints still used old schema queries — had to fix and redeploy.
- Typo `t.t` instead of `t.ts` in duc-viz JOIN conditions — caught during review.

**Improve / lesson**
- When normalizing a schema, update ALL consumers (server API, viz, clean) in the same commit to avoid partial-breakage redeployments.

## 2026-09-03 — duc-monitor MIN_SIZE filter

**Went well**
- Identified root cause: duc-parse stores every directory path, millions per scan.
- Added `--min-size` flag to duc-parse, `MIN_SIZE` env var to server and collector.
- Committed, pushed, deployed — all working on first try.
- Treemap still shows meaningful structure with 5MB filter.

**Went bad**
- Nothing significant.

**Improve / lesson**
- **duc databases grow unbounded** without size filtering. The `duc-clean` script only deduplicates timestamps, it doesn't reduce entries per timestamp. Always set `MIN_SIZE` on duc-monitor deployments.
- For large filesystems (>100GB), 5MB is a good default. For smaller systems, lower thresholds work fine.

## 2026-09-03 — duc-monitor on Coolify worker

**Went well**
- Replicated maripop duc-monitor setup on Coolify worker via MCP.
- API keys matched on first try (same `duc-monitor-secret-key-2024`).
- Scan completed in ~2 minutes, data received by duc-server.

**Went bad**
- `custom_docker_run_options: -v /:/host:ro` silently ignored — container had no mounts. Only discovered when ncdu produced empty JSON ("Invalid ncdu JSON").
- First deployment failed because repo is private and `create_public` was used instead of `create_github`.

**Improve / lesson**
- **Coolify `custom_docker_run_options` only supports a whitelist** (`--cap-add`, `--device`, `--privileged`, etc.). Volume mounts are NOT supported. Use **Persistent Storage** (bind mount) instead.
- Private repos need `create_github` with `github_app_uuid`, not `create_public`.
- Promoted to SKILL.md.

## 2026-09-02 — Dawarich blocked-hosts fix + env var management lesson

**Went well**
- Logs immediately revealed the "Blocked hosts: timeline.mariocake.de" error.
- Diagnosis was fast: missing `APPLICATION_HOSTS` env var in Coolify service.
- Coolify MCP `env_vars` create/update worked for adding the domain.

**Went bad**
- Initially set wrong env var (`RAILS_ALLOWED_HOSTS`) — Dawarich uses `APPLICATION_HOSTS` (verified in source: `config/environments/production.rb`).
- Had to SSH to verify the actual container env (`docker exec ... env | grep HOST`) — the MCP showed the var was created but the container still had the old value.
- The existing `APPLICATION_HOSTS` was `timeline.coolify.lan,localhost,::1,127.0.0.1` — Coolify's internal domain baked in, but user's public domain missing. Should have checked container env FIRST before assuming what was set.
- Restarted the service twice before realizing the env var wasn't being applied (Coolify caches compose, restart alone doesn't re-read env vars — need redeploy or force-recreate).

**Improve**
- Always `docker exec ... env` to verify what the container actually sees before assuming MCP env changes took effect.
- When an app uses a custom env var (not standard Rails `RAILS_ALLOWED_HOSTS`), check the app's source code for the actual variable name.
- For Coolify services: env var changes via MCP require a redeploy (not just restart) to propagate to containers.

**Promoted to SKILL.md**: Coolify env var propagation requires redeploy.

## 2026-08-31 — Five MCP servers installed for infrastructure management

**Went well**
- All 5 MCP servers installed and configured in one session.
- HA token extracted securely from lnxlink config (never entered agent context).
- SSH MCP config created with profiles for all 3 infrastructure hosts.
- Coolify RW MCP replaces manual curl commands with safety rails.
- Skill documentation updated with tool use cases and decision tree.

**Went bad**
- TrueNAS MCP needs API key (user action required).
- ha-mcp required npm install (pipx failed due to Python version).
- truenas-mcp-server had mcp v2 dependency conflict (fixed with pin).

**Improve**
- All secrets now in `~/.config/opencode/secrets/` with file references.
- Decision tree in skill makes it clear which server to use when.
- Reference doc updated with all config details.

**Promoted to SKILL.md**: MCP tool use cases section with decision tree.

## 2026-08-31 — Infrastructure session analysis + skill improvement

**Went well**
- Cross-session analysis identified 15+ infrastructure sessions with clear patterns.
- 8 deployment failures traced to root causes (3 Catan TS, 5 AnkiWeb SQLite).
- Agent behavior issues documented (circles, simultaneous changes, workarounds).
- 5 MCP servers researched with concrete install recommendations.
- Skill updated with: Coolify deployment workflow, SSH access protocol,
  pre/post-deploy checklists, one-change-at-a-time enforcement, MCP upgrade path.

**Went bad**
- Analysis took significant context to pull session data from SQLite DB.
- No centralized "what went wrong across all sessions" existed before this.

**Improve**
- Full analysis written to `~/docs/infrastructure/AGENT-ISSUES-ANALYSIS.md`.
- Skill now has deploy workflow, SSH protocol, and enforcement sections.
- MCP upgrade priority: Coolify (read+write) > HA > Docker > SSH > TrueNAS.

**Promoted to SKILL.md**: Coolify deployment workflow, SSH access protocol,
SQLite service pattern, pre/post-deploy checklists, one-change enforcement,
MCP upgrade recommendations.

## 2026-08-31 — Matrix Transcription Bot crash-loop fix

**Went well**
- Diagnosis was fast: logs immediately showed the 404 on key upload, and the
  compose file revealed the wrong `MATRIX_HOMESERVER` value.
- Coolify REST API worked for compose update (base64-encoded `docker_compose_raw`)
  and service control (restart/start).
- Fixed three issues in one pass: homeserver URL, Whisper port, network isolation.
- Used `id_opencode` SSH key for worker access (per user's suggestion).

**Went bad**
- First restart left the service in `exited` state — needed a manual start.
  Coolify reported "already running" while status was `exited` (stale state).
- Missed the `PARAKEET_URL` port mismatch on first compose update (kept the
  original 10199). Had to do a second compose patch + restart.
- SSH to worker with `id_rsa` didn't work (passphrase-locked key not in agent).
- Overlooked Whisper's auto-generated API key on persistent volume — bot
  transcriber didn't send Authorization header, causing 401 errors even after
  fixing the 404. Had to patch the bot source code and push via GitHub Actions.

**Improve**
- When updating compose, check ALL environment variables against expected values,
  not just the ones that seem broken.
- Verify `connect_to_docker_network` for multi-container services that reference
  each other by container name.
- Check if downstream services (Whisper) have auth requirements before assuming
  the client (bot) already handles them.
- The Coolify API's `config_hash` doesn't change on compose edits — always
  re-read the compose after patching to confirm.
