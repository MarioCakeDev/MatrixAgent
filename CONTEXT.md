# Context: Zooid — Matrix Agents for OpenCode

## Glossary

### Core concepts

**Workstation**
A single Zooid daemon with its own identity. Named via top-level `workstation:` in `zooid.yaml`. Every agent gets an exclusive `@{workstation}.{agent}:server` namespace. One daemon = one workstation.

**Application Service (AS)**
A Matrix protocol component that lets a daemon impersonate users and receive events. Requires registration on the homeserver: a `registration.yaml` file with `as_token`, `hs_token`, and namespace regex.

**Transport mode**
How daemon and homeserver connect:
- `appservice` (push): homeserver pushes events to daemon. Daemon advertises an address.
- `client` (pull): daemon fetches events. No inbound needed.

**Agent namespace**
The exclusive user ID range reserved for a workstation. Format: `@{workstation}.*:server`. Only the owning AS can create/manage users in this namespace.

**Agent harness**
The CLI tool an agent uses (OpenCode, Claude Code, Codex). Each has an ACP (Agent Client Protocol) shim that bridges the CLI to Matrix.

### Infrastructure

**Zooid**
Open-source, self-hostable Matrix-ACP bridge. Daemon runs as a "workstation" with agents as Matrix users. Pre-built images on GHCR.

**Synapse**
Matrix homeserver implementation. Runs in the Matrix service on Home Worker 01. Server name: `mariocake.de`.

**MAS (Matrix Authentication Service)**
OAuth 2.0 / OpenID Provider for Matrix. Handles user authentication. Admin API available for programmatic user management.

**Ketesa**
Admin UI for Matrix servers. Drop-in replacement for Synapse Admin. Has full MAS integration for user/session management.

**ACP (Agent Client Protocol)**
Open standard for agent communication. Backed by Zed and JetBrains. Zooid bridges ACP events to Matrix.

### Domain-specific

**Zooid daemon**
The bridge process that connects to a homeserver and manages agent containers. Each daemon is one workstation.

**Agent container**
Docker/Podman container spawned by the daemon for each agent. Auto-mounts workspace and preset state.

**Preset state**
Host directories auto-mounted into agent containers for auth persistence. Per harness: `~/.claude`, `~/.codex`, `~/.local/share/opencode` + `~/.config/opencode`.

### Cross-domain coordination

**Handoff**
A cross-domain request where one agent @mentions another in the target domain's room. Includes a summary of relevant context. Tracked via a Matrix thread with status reactions (OPEN → IN PROGRESS → DONE).

**Escalation**
When an agent cannot handle a handoff request, it @mentions the orchestrator in the same thread. Orchestrator evaluates, routes, or resolves the conflict.

**Orchestrator agent**
The coordination agent that joins all domain rooms and proactively monitors for cross-domain conflicts. Merged architect + reviewer roles. Does not write code or modify infrastructure — only coordinates and escalates.

### Related decisions

- **Deployment target**: Coolify worker (Home Worker 01), appservice mode
- **Homeserver integration**: External URL via Traefik, Ketesa for accounts, unencrypted rooms
- **Daemon networking**: Synapse reaches daemon via Traefik route at `zooid.coolify.lan`, daemon reaches Synapse via `https://matrix.mariocake.de`
- **Workstation name**: `agent` — agents are `@agent.{type}:mariocake.de`
- **Agent personas**: 5 agents (dev, infra, smarthome, orchestrator, general) with specific skills, MCPs, and workdirs. Separate AGENTS.md per agent. Skills auto-discovered from workdir. Dev agent workdir: MatrixAgent repo (static, dynamic switching deferred to Zooid).
