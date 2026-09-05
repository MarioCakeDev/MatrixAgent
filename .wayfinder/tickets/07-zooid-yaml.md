# Ticket: Zooid YAML Configuration

**Labels**: `wayfinder:done`
**Blocked by**: 02-homeserver-integration ✓, 03-agent-roster ✓, 04-room-structure ✓, 05-agent-personas _(deferred)_, 06-cross-domain-coordination ✓
**Blocks**: _(none — final ticket)_

## Question

What does the actual `zooid.yaml` configuration look like? This is the prototype ticket — once the deployment target, agent roster, and room structure are decided, we draft the config.

## Resolution

**Draft complete.** See `zooid.yaml` in the repo root.

### Configuration summary

| Setting | Value | Source |
|---------|-------|--------|
| Workstation | `agent` | Ticket 03 (corrected from ticket 02's `home`) |
| Runtime | `docker` | Ticket 01 (Coolify worker) |
| Transport mode | `appservice` (push) | Ticket 02 |
| Homeserver URL | `https://matrix.mariocake.de` | Ticket 02 (port 443 via Traefik) |
| Daemon advertise URL | `http://zooid.coolify.lan` | New: Traefik route on port 80 |
| AS registration URL | `http://zooid.coolify.lan` | Matches advertise URL |
| user_namespace | `@agent.*:mariocake.de` | Ticket 02/03 |
| Space | `zooid` (auto-created) | Ticket 04 |
| Container image | `ghcr.io/zooid-ai/agent-opencode:latest` | Global default |
| Agent trigger | `mention` | All agents |

### Agent room assignments

| Agent | Rooms | Rationale |
|-------|-------|-----------|
| dev | #dev, #handoffs | Domain room + cross-domain |
| infra | #infra, #handoffs | Domain room + cross-domain |
| smarthome | #home, #handoffs | Domain room + cross-domain |
| orchestrator | #dev, #infra, #home, #handoffs, #status | All rooms (merged architect role) |
| general | #handoffs | Cross-domain only |

### What's deferred

- **Agent workdirs**: TBD in ticket 05 grilling sessions (per-agent)
- **Agent personas (AGENTS.md, skills, MCP)**: Ticket 05
- **Container env vars**: None needed — OpenCode Go handles auth via preset state mount
- **Container mounts**: Deferred with personas

### Networking decision

Synapse reaches the daemon through a dedicated Traefik route at `zooid.coolify.lan`. This avoids:
- Modifying `connect_to_docker_network` on the Matrix service
- Host networking for the daemon
- Docker network sharing between services

The daemon reaches Synapse through the same Traefik proxy at `https://matrix.mariocake.de`.

### Scripts updated

- `scripts/generate-as-registration.sh` — workstation changed to `agent`, url to `http://zooid.coolify.lan`, exclusive to `false`
- `scripts/install-registration.sh` — adapted for Coolify-managed Matrix service (mount-based, not docker cp)

### Open questions resolved

1. **Does this match the actual Zooid YAML schema?** Yes — verified against zooid.dev/docs/guides/zooid-yaml/
2. **How are env vars and secrets injected?** Not needed — OpenCode Go uses preset state mount for auth
3. **Volume mount paths**: Deferred to ticket 05 (per-agent workdirs)
4. **Network mode**: External URL via Traefik (`zooid.coolify.lan`)
5. **Health checks**: Deferred — not in scope for initial config
