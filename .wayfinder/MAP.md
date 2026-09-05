# Wayfinder Map: Zooid — Matrix Agents for OpenCode

## Destination

Deploy Zooid on the Coolify infrastructure, connecting OpenCode AI agents to the existing Matrix homeserver (`mariocake.de`). Five agents — dev, infra, smarthome, orchestrator, general — each as a Matrix user. The orchestrator coordinates cross-domain handoffs. Easy handoffs between domains when a project needs infrastructure changes, a smart home task needs code, etc.

## Notes

- **Existing Matrix stack**: Synapse on `matrix.mariocake.de` (Home Worker 01, 192.168.1.92), MAS for OIDC, Ketesa admin UI, Telegram/Signal/WhatsApp bridges, Matrix Transcription Bot.
- **Servers**: maripop (desktop PC, Pop!_OS 24.04, COSMIC), Home Worker 01 (Coolify worker, Debian 13), coolify-worker-uk-oracle, Coolify master (192.168.1.90).
- **Zooid**: Open-source, self-hostable Matrix-ACP bridge. Pre-built `ghcr.io/zooid-ai/agent-opencode` image. Daemon runs as a "workstation" with agents as Matrix users.
- **Transport modes**: `appservice` (push, homeserver pushes to daemon) or `client` (pull, daemon fetches). Client mode better for LAN/home setup.
- **Agent workdir**: Persona files (AGENTS.md, skills, MCP servers) live on host, bind-mounted into container.

## Decisions so far

- [Deployment Target](tickets/01-deployment-target.md) — **Coolify worker (Home Worker 01)**, `appservice` mode. Always-on, same Docker network as Synapse, 8 CPUs / ~15 GB RAM available. Agent workdirs on worker's disk, bind-mounted into containers. maripop may become a second workstation later.
- [Agent Roster](tickets/03-agent-roster.md) — **5 agents**: dev, infra, smarthome, orchestrator, general. All use `opencode` harness. Workstation name: `agent` → Matrix IDs `@agent.{type}:mariocake.de`. Single MatrixAgent repo for everything.
- [Room & Space Structure](tickets/04-room-structure.md) — **Single 'Zooid' top space** → per-domain subspaces → 5 minimal rooms (Dev, Infra, Home, Handoffs, Status). Encrypted by default. Agents scoped to domain + handoffs. Hybrid threading. Direct agent-to-agent @mentions for cross-domain.
- [Agent Personas & Skills](tickets/05-agent-personas.md) — **5 agent personas defined**: dev (coding loop, MatrixAgent workdir), infra (infrastructure stack), smarthome (HA API only), orchestrator (coordination), general (catch-all). Separate AGENTS.md per agent. Skills auto-discovered from workdir. MCP config via workdir files + env vars. Secrets via zooid.yaml container.env.

## Ticket index

### Frontier (unblocked, takeable now)

_(none — all tickets done)_

### Decided (awaiting implementation details)

_(none)_

### Done

| # | Ticket | Type | Status |
|---|--------|------|--------|
| 01 | [Deployment Target](tickets/01-deployment-target.md) | decision | Coolify worker, appservice mode |
| 02 | [Homeserver Integration](tickets/02-homeserver-integration.md) | research | Appservice, external URL, Ketesa for accounts, unencrypted |
| 03 | [Agent Roster & Harnesses](tickets/03-agent-roster.md) | grilling | 5 agents, all opencode, workstation `agent` |
| 04 | [Room & Space Structure](tickets/04-room-structure.md) | grilling | Single Zooid space → subspaces → 5 minimal rooms, encrypted, scoped permissions |
| 05 | [Agent Personas & Skills](tickets/05-agent-personas.md) | grilling | 5 personas defined, dev workdir TBD |
| 06 | [Cross-Domain Coordination](tickets/06-cross-domain-coordination.md) | grilling | @mentions in domain rooms, thread-based tracking, architect escalation |
| 07 | [Zooid YAML Configuration](tickets/07-zooid-yaml.md) | prototype | Draft complete, agent personas now resolved |

### Blocked

_(none)_

### Dependency graph

```
01 Deployment Target (DONE) ─┬──► 02 Homeserver Integration (DONE) ──┐
                             ├──► 03 Agent Roster (DONE) ─┬──► 05 Personas (DONE)
                             │                             └──► 06 Cross-Domain (DONE)
04 Room Structure (DONE) ────┘                             └──► 07 Zooid YAML (DONE)
```

## Not yet specified

- Whether maripop desktop also runs a Zooid workstation (local agents alongside Coolify-hosted ones)
- Integration with existing bridges (Telegram/Signal/WhatsApp) for agent notifications
- Backup/restore strategy for Zooid state and agent workdirs
- Monitoring and alerting for the Zooid daemon

## Out of scope

_(none yet)_
