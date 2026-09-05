# ADR: Agent Personas & Skills

**Status:** Accepted  
**Date:** 2026-09-05  
**Deciders:** Mario  
**Ticket:** 05-agent-personas

## Context

Each agent needs a persona that defines its role, skills, MCP server access, and constraints. We need to decide what goes into each agent's AGENTS.md and how skills/MCPs/secrets are configured.

## Decision

### Agent roster (5 agents)

| Agent | Skills | MCP Servers | Workdir | Secrets |
|-------|--------|-------------|---------|---------|
| `dev` | implement, tdd, code-review, diagnosing-bugs, research, wayfinder | GitHub, Docker, Coolify (read-only) | MatrixAgent repo | GitHub token, Coolify token (read-only) |
| `infra` | infrastructure, diagnosing-bugs, research | Coolify, SSH, Docker, TrueNAS, Home Assistant | MatrixAgent repo | Coolify token, SSH keys, HA token |
| `smarthome` | Home Assistant MCP, research, diagnosing-bugs | Home Assistant WebSocket | None | HA token |
| `orchestrator` | domain-modeling, grill-me, wayfinder | None (built-in Matrix context MCP) | MatrixAgent repo | None |
| `general` | research, web search | None | None | None |

**Why these skill assignments:**
- Dev gets the full coding loop (implement → test → review → debug) plus research/wayfinder for planning
- Infra gets the infrastructure skill workflow plus diagnostics and research for investigating options
- Smarthome is focused on HA API interaction only, no filesystem access
- Orchestrator coordinates via Matrix, doesn't write code or modify infra
- General is a catch-all with minimal tooling

**Why dev gets Coolify read-only:**
- Dev needs to check deployment status and preview environments
- Read-only prevents dev from accidentally modifying infrastructure
- Full Coolify access is infra's responsibility

### AGENTS.md structure: Separate files per agent

Each agent gets its own AGENTS.md in its workdir. No shared base file.

**Why separate over shared base + overrides:**
- Simpler — no override logic or merge conflicts
- Each agent's persona is self-contained and easy to review
- Avoids accidentally inheriting constraints from other agents

### Skill loading: Auto-discovered from workdir

Zooid auto-discovers skills from the workdir's standard locations (e.g., `.opencode/skills/` for OpenCode). No explicit skill path configuration needed in zooid.yaml.

### MCP server configuration: Workdir files + env vars

External MCP servers (Coolify, HA, Docker, etc.) are configured via:
1. Config files in the agent's workdir (e.g., `.opencode/mcp.json`)
2. Environment variables passed via `container.env` in zooid.yaml

**Why both:**
- Config files define the MCP server structure (command, args)
- Env vars inject secrets (tokens, URLs) without hardcoding

### Secrets: zooid.yaml container.env

Secrets are injected via `container.env` in zooid.yaml using `${VAR}` references from the daemon's environment.

**Why not workdir .env files:**
- Centralizes secret management in zooid.yaml
- Avoids secrets on disk in workdir
- Consistent with Zooid's security model

## Consequences

### Positive
- Clear separation of concerns per agent
- Each agent's capabilities are explicit and auditable
- Secrets managed centrally via zooid.yaml
- Skills auto-discovered, no manual path config
- Dev agent works on its own infrastructure (MatrixAgent repo)

### Negative
- Dev agent limited to MatrixAgent repo until Zooid supports dynamic workdir switching
- MCP config in workdir means each agent needs its own config files
- Separate AGENTS.md means some duplication of common rules

### Risks
- If agent roles change frequently, maintaining separate AGENTS.md files adds overhead (mitigated: personas are stable)
- MCP config in workdir may drift between agents (mitigated: can be templated)
- Dev agent's static workdir may feel limiting if projects diversify (mitigated: Zooid plans dynamic workdir feature)
