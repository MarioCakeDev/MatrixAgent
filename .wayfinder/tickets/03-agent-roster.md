# Ticket: Agent Roster & Harnesses

**Labels**: `wayfinder:done`
**Blocked by**: _(resolved: 01-deployment-target → Coolify worker, appservice mode)_
**Blocks**: 05-agent-personas, 06-cross-domain-coordination, 07-zooid-yaml

## Question

Which agents should exist, what ACP harness does each use, and what are their workdirs?

## Decisions

### Workstation naming

- **Workstation**: `agent`
- **Matrix IDs**: `@agent.dev:mariocake.de`, `@agent.infra:mariocake.de`, `@agent.smarthome:mariocake.de`, `@agent.orchestrator:mariocake.de`

### Agent roster (5 agents)

| Agent | Domain | Harness | Workdir | Purpose |
|-------|--------|---------|---------|---------|
| `dev` | Software Development | opencode | _(per-project, TBD)_ | Writes code, runs tests, makes PRs |
| `infra` | Infrastructure | opencode | _(TBD)_ | Manages Coolify, servers, docker, configs. Follows existing `/infrastructure` skill workflow (inventory → gate → snapshot → journal) with same MCP tools (coolify, ha, docker, ssh, truenas) |
| `smarthome` | Smart Home | opencode | _(TBD)_ | Full Home Assistant control — lights, climate, automations, device states, creating new HA automations |
| `orchestrator` | Cross-domain | opencode | _(TBD)_ | Active project manager — monitors all domain rooms, routes tasks between agents, opens threads for new topics, handles handoffs |
| `general` | General | opencode | _(TBD)_ | Random questions, research, web search, info lookup |

### Key decisions

1. **All agents use opencode** — consistency, no harness variety.
2. **Architect + reviewer merged into orchestrator** — single active project manager instead of two separate cross-domain agents.
3. **Multiple dev agents per project** — each project gets its own dev agent with a fixed workdir (Zooid workdirs are static per agent).
4. **Single MatrixAgent repo** — holds everything: zooid.yaml, deployment config, and all agent personas (AGENTS.md, skills, MCP configs).
5. **Workdir/MCP/tools deferred** — to separate grilling sessions per agent.

### Resolved research questions

- **Workdir switching**: Static per agent in `zooid.yaml`. No runtime switching. Use `container.mounts` for additional paths.
- **Multi-room**: Yes, agents can be in multiple rooms — `rooms:` is a list.
- **Multiple agents in same room**: Yes, each is a separate Matrix user.
- **Harness presets available**: `claude`, `codex`, `opencode`, `cline`, `kiro`, `gemini`.

### Deferred

- Workdir paths for each agent (separate grilling sessions)
- MCP server configs per agent (separate grilling sessions)
- Room assignments (ticket 04)
- Resource limits per container (ticket 07)
