---
name: infrastructure
description: "Use when the user wants to change ANYTHING on their infrastructure or talks about it ('infrastructure', 'the network', 'my server', 'this pc', 'my desktop', 'system', 'install', 'update packages'). Covers this PC (maripop): packages/installs/updates, systemd services, docker, cron, desktop & OS config (COSMIC window rules, tiling exceptions, themes, `~/.config` edits), hardware, system settings, service restarts. Covers the Coolify server (SSH, `coolify.lan`) and LAN devices (Home Assistant, TrueNAS, router, new devices). Reads and updates the entity catalog in `~/docs/infrastructure/`; confirms before gated changes."
---

# Infrastructure

Control and document your home network — this PC (`maripop`), the Coolify server, and the LAN devices. The entity catalog lives in `~/docs/infrastructure/`, separate from this skill. Run every task through the loop — **inventory → gate → snapshot → journal** — and never run a gated change without an explicit yes. Status queries about infra count as tasks (read-only: free to run, no journal).

## secrets — never in context

Secrets must never enter the agent context or appear in any tool output, logs, or docs.

- **Never read a file that may contain secrets** — no `cat`/`read`/`grep` of values from config files (e.g. `*_config.yml`, `.env`, `credentials*`, `*.ini`, keyring files). Treat any file under these names as a secrets file.
- If config values are needed, **run a script that reads the file in-process and prints only masked metadata** (key names, value types, lengths) — never values, never substrings, never head/tail previews.
- To rotate or update a secret, do **read → transform → write in a single non-echoing command**; the only output is a boolean/status line (e.g. "token written", length). Never `cat` the result back.
- Never paste, commit, log, or echo a secret into a prompt, file, doc, or changelog. Mask in docs as `***`.
- When you must use a secret for an API call, the shell reads it from its file; the command text and output must not contain it.

## inventory — read before acting

Grep the **tag index** in `~/docs/infrastructure/` first, then read the matched entity files: their content **is** the before-state, so no separate staging. Read the recent sections of `RETROSPECTIVE.md` so the journal's lessons are in view. Reuse existing tags freely; a new tag needs the user's approval.

Bootstrap lazily: if the docs folder doesn't exist, this task creates it — `entities/`, tag index, `CHANGELOG.md`, `CONTEXT.md` — and inventories only what it touches (the devices it controls and the local-domain aliases it uses), marked honestly.

_Criterion: every entity this task touches is read, recent journal sections in view._

## gate — confirm before changing

- **PC (maripop)**: any system-level change confirms — package installs/updates, config edits, docker changes, service restarts. Free: read-only checks and writing to the docs folder.
- **Server (`coolify.lan`) and LAN devices**: any change confirms; read-only inspection (status, `docker ps`, logs, disk) is free.

Restate the change, what it affects, and what's irreversible, showing the **exact command(s) + effect**, then ask an explicit yes/no. Nothing runs until yes. If the user is unavailable and the change can't wait, hold it and note in the docs what you wanted to do.

_Criterion: a gated change runs only after an explicit yes._

## snapshot — write on done

Update the touched entity files (state + append each file's `History`), then append a `CHANGELOG.md` session entry: what changed, who made it (agent/user), before/after.

Fog stays honest: anything unverified lands in the entity's `known-unknowns` and as a loose `CONTEXT.md` entry. When an unknown blocks the task, resolve it inline — read-only investigation first, then the gate if a change follows — and update the docs the same run. No separate fog step.

_Criterion: every entity this task changed is updated, changelog entry written._

## journal — grow the skill

For change-tasks only, a hard gate: the task is not done until this runs. Prepend an entry to `RETROSPECTIVE.md` (newest first): went well / went bad / improve. Record user-made changes too — who made what; ask if unsure. A lesson promotes into this file when it recurred across 2+ tasks or changed behavior; single occurrences stay in the journal. Read-only tasks earn no entry.

_Criterion: retro entry prepended, or the task was read-only._

## Operational lessons

These recur across tasks; violating any of them costs time.

### Diagnosis first, fix second

Trace the full query path before installing a workaround. If a fix doesn't work, the root cause is elsewhere — don't pile on more workarounds.

- **Router DNS hijack** (2026-08-30): installed AdGuard dnsproxy before finding the real cause (adblock-fast redirecting port 53). Should have traced `dig` output to the router first.
- **AnkiWeb Locked:** (2026-08-15): assumed volume/perm problem; it was Coolify rolling-update overlap. A controlled experiment (stop → deploy vs. pure start) proved it.
- **BackInTime outage** (2026-08-19): log forensics reconstructed the full chain without root shell — always read logs before acting.

### One change at a time

Changed 4 things simultaneously on the Matrix bot (MAS login, E2EE, auto-join, logging). Couldn't isolate which fixed what. Make one change, verify, commit, then move on.

### Test in the right context

Commands that work interactively may fail in scripts/cron:

- `step ca renew` fails with `open /dev/tty failed` in cron — had to use `step ca certificate --force` instead.
- Test renewal commands in a non-interactive context before committing.

### Use the platform's API

Editing Coolify-managed files (docker-compose.yml) directly works until the next deploy overwrites them. Make changes through the Coolify API or UI.

### Verify assumptions, not just outcomes

- **UK API key vs password**: burned 2 deploy cycles — UK v2 API keys are metrics-only, can't log in to socket.io. Ask up front whether a credential is an API key or a login password.
- **SSH "verified"**: entity file said "verified same day" but the key was passphrase-protected and locked. Re-probe SSH at task start.
- **Bot could receive**: assumed the bot could send messages but wasn't — it couldn't receive at all. Spent hours debugging reply formatting for a non-issue.

### Coolify service creation needs all IDs

The `coolify-rw_service` create action requires `server_uuid`, `project_uuid`, AND `environment_name` (or `environment_uuid`). Just `project_uuid` alone fails. Get server UUID from `list_servers`, project details from `get_project` (includes environments).

### Docker changes require recreation

`docker restart` doesn't re-read labels. After editing compose labels or env vars, use `docker compose up -d --force-recreate`.

### Platform-specific gotchas

- **Coolify API**: service sub-application `fqdn` is read-only via API. For domain changes, use the UI or modify docker-compose directly.
- **Coolify rolling updates + SQLite**: expect `Locked:` errors. Stop the old container fully before deploying. Enable `is_consistent_container_name_enabled` for stateful apps.
- **HA add-ons**: a stopped add-on's container is absent by design. Query `ha addons info` + add-on logs, not just `docker ps`.
- **Cloudflare tunnels**: a hostname may already route to the old origin. Check `cloudflared` logs for `originService=` before creating.
- **Cloudflare DNS propagation**: DNS-01 challenges may need `propagationtimeout=300` in Traefik's ACME settings.
- **For COSMIC window identity**: go straight to `ext-foreign-toplevel-list-v1` client — AT-SPI and `wlrctl` are dead ends.
- **For HA token work**: go straight to WebSocket API with a browser UA; the REST long-lived-token route is dead.
- **nftables on OpenWrt fw4**: use `/etc/init.d/` scripts for boot persistence; fw4 reloads regenerate the full ruleset.
- **Never modify /etc/resolv.conf without a rollback plan**: circular dependency if the replacement isn't running.
- **SSH keys for cron**: must be passphrase-less. Passphrase-protected keys fail silently when the agent isn't running.
- **Steam Cloud for single-save games**: disable it or it silently overwrites local saves on launch.
- **Flatpak Steam**: check `~/.var/app/com.valvesoftware.Steam/.local/share/Steam/` for cloud cache, not `~/.local/share/Steam/`.
- **Coolify env var changes require redeploy**: `coolify-rw_env_vars` updates the store but containers keep old env until redeployed. Use `coolify_deploy` or `docker compose up -d --force-recreate`.
- **Coolify compose is cached**: editing `docker_compose_raw` via API does update the store, but running containers keep the old compose until next deploy.
- **Coolify `custom_docker_run_options`**: only supports a whitelist (`--cap-add`, `--device`, `--privileged`, `--shm-size`, etc.). Volume/bind mounts are silently ignored. Use **Persistent Storage** (bind mount via `coolify-rw_storages`) for host path mounts.

### Cleanup tasks

- Snapshot `df -h` before and after; report measured reclaimed space, not item-size estimates.
- Include hidden-dir sizes (`du -sh ~/.* `) — visible-only misses ~260 GB on this box.
- Each independent deletion as its own command — `&&` chains silently skip on failure.
- Check directory ownership before bulk delete; mixed-owner trees need escalation.
- For WebDAV copies: copy → verify byte-identical → delete originals.

### Backups and freshness

- After fixing backup systems, confirm with the next scheduled run, not just a manual forced snapshot.
- Re-check snapshot freshness as a standing check — stale backups are a recurring blind spot.
- For Flatpak Steam installations, check cloud cache path before disk scanning.

## Deploying to Coolify

### Code provisioning — three paths

Coolify cannot create arbitrary files on the server. Code must come from one of:

1. **Git repository (preferred)**: Push to a GitHub/GitLab repo (private or public).
   Coolify pulls and builds. Use the GitHub app integration for private repos.
   ```bash
   # Create private repo, push code, then create Coolify app pointing to it
   gh repo create <name> --private --source=. --push
   ```

2. **Coolify UI upload**: Create application → upload files via the dashboard.
   Good for single-file scripts or small projects.

3. **Volume mount**: Place files in a named volume or bind mount path on the
   worker via SSH. Use for config files, not application code.

**Never**: try to create files directly on the worker expecting Coolify to find them.
Coolify only knows about code from git repos or UI uploads.

### Coolify write operations

For writes (deploy, restart, update compose, create apps), use the
`coolify-rw` MCP server. It has safety rails — destructive ops require
human confirmation.

**Known limitations**:
- Service sub-application `fqdn` is read-only via MCP (use UI or docker-compose
  label manipulation for domain changes on services).
- `config_hash` doesn't change on compose edits — always re-read compose after
  patching to confirm.

### SQLite service pattern

Services using SQLite (AnkiWeb, some bots) must use stop-first deploys:

1. **Stop** the running container (not just restart)
2. **Deploy** the new image
3. **Start** the container

Rolling updates cause `Locked:` errors because old + new containers compete for
the same SQLite file on the shared volume.

For durable protection, enable consistent container names via the
`coolify-rw` MCP server.

### Pre-deploy checklist

Before deploying any change to Coolify:

- [ ] Local build test passed (if applicable: `npm run build`, `docker build`)
- [ ] ALL environment variables verified against expected values
- [ ] Volume/mount requirements checked (persistent data, config files)
- [ ] Network connectivity between services verified (container names, ports)
- [ ] Downstream service auth requirements checked (API keys, tokens)
- [ ] Rollback plan identified (previous image tag, compose backup)
- [ ] All secrets in Coolify env var store, NOT in compose file
- [ ] No `${SECRET:-actual_value}` patterns with real fallback values in compose

### Post-deploy verification

After every deployment:

1. Container status: `coolify_get_application` → status should be `running:healthy`
2. Logs: `coolify_get_logs` → check last 50 lines for errors
3. Functional test: curl the endpoint, test the actual feature
4. If service depends on other services: verify inter-service communication
5. Secrets audit: `docker exec <container> env` — confirm no secrets appear in compose file or logs

## Coolify Docker Compose — env vars and secrets

### Core principle: compose files are semi-portable

Docker Compose files must be **shareable without leaking secrets**. Every secret
(password, API key, token, private key) lives in Coolify's env var store, NOT in
the compose file. Compose files reference env vars via `${VAR_NAME}` syntax.

**Why**: You may share compose files with others, paste them in issues, or commit
them to repos. If a secret is hardcoded, it leaks. If it's a `${VAR}`, the file
is safe.

### Env vars: always via Coolify UI/MCP/API

Every environment variable that may be changed at runtime MUST be managed through
Coolify — never hardcoded in `docker-compose.yml` or `docker-compose_raw`.

**Workflow**:
1. Check current env: `coolify-rw_env_vars` action=list
2. Check container reality: `docker exec <container> env | grep KEY`
3. Create/update via `coolify-rw_env_vars` action=create/update
4. **Redeploy** (not just restart) for changes to propagate

**Why redeploy, not restart**: Coolify caches compose on deploy. Restart alone
does not re-read env vars from the Coolify store. A redeploy or
`docker compose up -d --force-recreate` is required.

### Secrets — absolute rules

1. **NEVER put secrets in compose files** — not even as `${SECRET:-default}` with
   a fallback. If the fallback contains a real secret, it leaks.
2. **NEVER echo, log, or document secret values** — mask as `***` everywhere.
3. **NEVER read secret files into agent context** — no `cat`, `read`, `grep` of
   values. Use scripts that print only key names and metadata.
4. **Rotate secrets through Coolify MCP** — read old value from file in-process,
   generate new value, write via Coolify API, output only status.
5. **Verify rotation**: after rotating, `docker exec ... env` confirms the new
   value is in the container (but never print the value itself).

### Common secret patterns to recognize

These formats MUST be treated as secrets and never exposed:

| Pattern | Example prefix/format | Where found |
|---------|----------------------|-------------|
| API keys | `sk-`, `ak_`, `ghp_`, `gho_`, `glpat-` | Env vars, config files |
| JWTs | `eyJ` (base64 header) | Auth tokens, OIDC |
| Passwords in URLs | `redis://:password@host` | REDIS_URL, DATABASE_URL |
| PEM keys | `-----BEGIN ... PRIVATE KEY-----` | SSH keys, TLS certs |
| Hex strings (32+) | `[a-f0-9]{32,}` | SECRET_KEY_BASE, tokens |
| Base64 blobs (40+) | `[A-Za-z0-9+/]{40,}=` | Encoded secrets |
| Connection strings | `postgres://user:pass@host` | DATABASE_URL |
| SMTP credentials | SMTP_USERNAME, SMTP_PASSWORD | Email config |

**If you encounter any of these in tool output, logs, or file reads**:
1. Do NOT include in your response
2. Report that a secret was detected
3. Recommend rotation if it was exposed to the agent context

## SSH access protocol

### At task start — always verify

```bash
# Test SSH with the intended key
ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no \
  -i ~/.ssh/id_opencode root@coolify.lan "echo OK" 2>&1
```

If this fails:
- Check if key exists: `ls -la ~/.ssh/id_opencode`
- Check if key is passphrase-locked: `ssh-keygen -y -f ~/.ssh/id_opencode` (fails if locked)
- If passphrase-locked, use a different key or ask user to unlock

### Key selection

- **Infrastructure tasks**: use `~/.ssh/id_opencode` (passphrase-less)
- **BackInTime/backup tasks**: use `~/.ssh/maripop-backup` (passphrase-less since 2026-08-19)
- **Never assume** a key works based on old documentation — re-probe every session

### SSH keys for cron

Keys used in cron jobs MUST be passphrase-less. Cron cannot unlock
passphrase-protected keys (no ssh-agent, no desktop session). If a cron job
fails with "Could not unlock ssh private key", the key needs its passphrase
removed.

## Enforce: one change at a time

When making infrastructure changes:

1. Make ONE change
2. Verify it works (container healthy, endpoint responding, feature working)
3. Commit/document the change
4. Then make the next change

**Never** bundle multiple changes and hope they all work. If something fails,
you need to know which change caused it.

Exception: changes that are logically atomic (e.g., setting two env vars that
must both be present for the service to start). In that case, document them as
a single change.

## Control

Use MCP tools as the primary channel. SSH to `coolify.lan` is still needed for low-level docker operations (label edits, manual cert issuance, iptables) and remote access to truenas.lan / router.lan.

## MCP tools — what to use when

Six MCP servers are configured. Use the right one for each task:

### Coolify (two servers)

| Server | When to use | Key tools |
|--------|-------------|-----------|
| **coolify** (built-in, read-only) | Quick status checks, listing resources, reading logs | `get_infrastructure_overview`, `list_unhealthy_resources`, `get_logs`, `list_deployments` |
| **coolify-rw** (StuMason, read+write) | Deploying, restarting, updating compose, creating apps | `deploy_application`, `restart_application`, `update_service_compose`, `create_application` |

**Rule**: Start with `coolify` (built-in) for reads. Switch to `coolify-rw` only when you need to write/deploy. The `coolify-rw` server has safety rails — destructive ops require human confirmation.

### Home Assistant

| Server | When to use | Key tools |
|--------|-------------|-----------|
| **ha** | Querying device states, calling services, managing automations, listing entities | `get_states`, `get_state`, `call_service`, `list_entities`, `list_services`, `fire_event` |

**Use cases**:
- "What's the temperature in the living room?" → `get_states` with domain `sensor`
- "Turn off the kitchen lights" → `call_service` with `light.turn_off`
- "Show me all motion sensors" → `list_entities` with device_class `motion`
- "Trigger the morning automation" → `fire_event` or `call_service` with `automation.trigger`

**Replaces**: Manual SSH + `curl` to `hass.lan:8123`, WebSocket connections, reading lnxlink config.

### Docker (local)

| Server | When to use | Key tools |
|--------|-------------|-----------|
| **docker** | Managing local containers on maripop (lnxlink, aniworld-downloader) | List/start/stop/restart containers, list images, manage volumes |

**Use cases**:
- "What containers are running locally?" → list containers
- "Restart the lnxlink container" → restart container
- "Check aniworld-downloader logs" → get container logs

**Note**: For Coolify server containers, use the Coolify MCP instead (it has deployment context).

### SSH

| Server | When to use | Key tools |
|--------|-------------|-----------|
| **ssh** | Remote shell access to coolify.lan, truenas.lan, router.lan | Execute commands on configured hosts |

**Profiles**: `coolify` (192.168.1.92), `truenas` (192.168.1.55), `router` (192.168.1.1)

**Use cases**:
- "Check disk space on the server" → `ssh` to coolify, run `df -h`
- "What's the TrueNAS pool status?" → `ssh` to truenas, run `zpool status`
- "Show router DNS config" → `ssh` to router, run `cat /etc/config/dhcp`

**Safety**: All destructive commands require human approval (`approvalMode = "ask-destructive"`).

### TrueNAS

| Server | When to use | Key tools |
|--------|-------------|-----------|
| **truenas** | Checking backup status, storage pools, datasets, snapshots | System info, storage pools, datasets, snapshots, SMB shares |

**Use cases**:
- "When was the last backup?" → check backup snapshots
- "How much space is left on the pool?" → check storage usage
- "List all datasets" → enumerate datasets

### Decision tree

```
Is it about Coolify/deployments?
  ├─ Read-only (status, logs, list) → coolify (built-in)
  └─ Write (deploy, restart, update) → coolify-rw (StuMason)

Is it about Home Assistant/devices?
  └─ ha

Is it about local Docker on maripop?
  └─ docker

Is it about remote server access (shell)?
  └─ ssh (with profile: coolify/truenas/router)

Is it about TrueNAS storage/backups?
  └─ truenas
```

## Composition

`CONTEXT.md` (in `~/docs/infrastructure/`) is the glossary of infra terms — maintain it with `domain-modeling` as terms sharpen. Consult `grilling` for decisions, `research` for facts, `writing-great-skills` when pruning this file.
