# Ticket: Agent Personas & Skills

**Labels**: `wayfinder:done`  
**Blocked by**: 03-agent-roster  
**Blocks**: 07-zooid-yaml

## Question

What goes into each agent's `AGENTS.md` and skill configuration? Each agent needs a persona that defines its role, constraints, and available tools.

## Decisions

### Agent roster (5 agents — matches ticket 03)

| Agent | Skills | MCP Servers | Workdir | Secrets |
|-------|--------|-------------|---------|---------|
| `dev` | implement, tdd, code-review, diagnosing-bugs, research, wayfinder | GitHub, Docker, Coolify (read-only) | MatrixAgent repo | GitHub token, Coolify token (read-only) |
| `infra` | infrastructure, diagnosing-bugs, research | Coolify, SSH, Docker, TrueNAS, Home Assistant | MatrixAgent repo | Coolify token, SSH keys, HA token |
| `smarthome` | Home Assistant MCP, research, diagnosing-bugs | Home Assistant WebSocket | None | HA token |
| `orchestrator` | domain-modeling, grill-me, wayfinder | None (built-in Matrix context MCP) | MatrixAgent repo | None |
| `general` | research, web search | None | None | None |

### Key decisions

1. **Separate AGENTS.md per agent** — no shared base file, each agent's persona is self-contained.
2. **Skills auto-discovered from workdir** — Zooid picks up skills from standard locations (e.g., `.opencode/skills/`).
3. **MCP config: workdir files + env vars** — config files define structure, env vars inject secrets.
4. **Secrets via zooid.yaml container.env** — `${VAR}` references from daemon environment, centralized management.
5. **Dev workdir: MatrixAgent repo** — single static workdir, dynamic switching planned for future Zooid release.

### Resolved research questions

- **Skill loading**: Zooid auto-discovers skills from workdir. No explicit config needed.
- **MCP server access**: Config in workdir (`.opencode/mcp.json`) + env vars in zooid.yaml.
- **Secrets per agent**: `container.env` in zooid.yaml with `${VAR}` refs.
- **Dev workdir**: MatrixAgent repo. Single static workdir, dynamic switching deferred to future Zooid feature.

### Deferred

_(none — all decisions resolved)_

## ADR

[0004-agent-personas.md](../../docs/adr/0004-agent-personas.md)
