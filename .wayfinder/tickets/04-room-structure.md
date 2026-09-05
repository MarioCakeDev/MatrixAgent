# Ticket: Room & Space Structure

**Labels**: `wayfinder:grilling`
**Blocked by**: _(none — can be decided independently)_
**Blocks**: 06-cross-domain-coordination, 07-zooid-yaml

## Question

How should Matrix rooms and spaces be organized for the three domains + cross-domain coordination?

## Decisions

### Structure

- **Single 'Zooid' top space** → per-domain subspaces → rooms
- Each domain (Software Development, Infrastructure, Smart Home) gets its own sub-space under the top-level "Zooid" space
- Cross-domain and status rooms live in the top-level space

### Room list (5 minimal rooms)

| Room | Location | Topic |
|------|----------|-------|
| `#dev:mariocake.de` | 💻 Software Development sub-space | General dev chat, code review, project discussions |
| `#infra:mariocake.de` | 🖥️ Infrastructure sub-space | Coolify, servers, docker, system management |
| `#home:mariocake.de` | 🏡 Smart Home sub-space | Home Assistant, automations, device management |
| `#handoffs:mariocake.de` | Zooid top space | Cross-domain requests and coordination |
| `#status:mariocake.de` | Zooid top space | Agent task status updates and health checks |

### Threading

- **Hybrid**: Threads for small tasks, separate rooms when agent decides
- Agent decides when to create a room vs. use a thread
- No fixed threshold — agent uses context to decide

### Encryption

- **Encrypted by default** for all rooms
- Agent containers need E2EE key management support

### Room permissions

- **Agents scoped to domain + handoffs**: Can only post in their own domain room + `#handoffs`
- **Agents can invite other agents** to rooms they're already in
- No logs room (logs stay in container filesystems, pulled on demand)
- No welcome room (onboarding happens in domain rooms when needed)

### Cross-domain coordination

- **Direct agent-to-agent @mentions** in domain rooms
- Agents @mention each other directly when cross-domain work is needed
- Context stays in the room where it's relevant

### Architect agent

- Joins **all rooms** (domain rooms + cross-domain rooms)
- Full visibility for conflict detection and coordination

### Room topics

- Yes, descriptive topics for each room
- Helps agents understand room purpose before joining

### Existing rooms

- **Fresh start** — agents start in new rooms
- Can join existing Transcription Bot rooms later if needed

## Open questions resolved

1. **Spaces vs. flat rooms**: Single top space + per-domain subspaces
2. **Threading**: Hybrid — agent decides threads vs. rooms
3. **Room encryption**: Encrypted by default
4. **Room permissions**: Agents scoped to domain + handoffs, can invite other agents
5. **Notification routing**: Direct agent-to-agent @mentions
6. **Existing rooms**: Fresh start, join later if needed
