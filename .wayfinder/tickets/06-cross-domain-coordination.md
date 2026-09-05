# Ticket: Cross-Domain Coordination

**Labels**: `wayfinder:grilling`
**Blocked by**: _(resolved: 03-agent-roster ✓, 04-room-structure ✓)_
**Blocks**: 07-zooid-yaml

## Decisions

### Handoff mechanism: Direct @mentions in domain rooms

Agents @mention each other directly in the target domain's room. No dedicated handoff room needed for the mechanism itself — context stays local to the domain.

### Message format: Natural language

No structured templates. Agent A writes what it needs in plain language. Keeps things flexible and human-readable.

### Context passing: Agent A provides summary

When handing off, Agent A includes a summary of relevant context in the @mention message. Agent B gets enough background to start working without needing to read A's conversation history.

### State tracking: Thread-based

Each cross-domain handoff gets a Matrix thread. Status updates go in the thread:
- 🔵 OPEN — request received, not yet started
- 🟡 IN PROGRESS — agent is working on it
- 🟢 DONE — task completed

### Escalation: To architect in the same thread

If Agent B can't handle a request, it @mentions the architect in the same handoff thread. Architect evaluates and routes or resolves.

### Architect scope: Active monitoring

Architect agent joins all domain rooms and proactively monitors for conflicts. Not just escalation-only — architect can intervene when it detects cross-domain issues.

### Work location: Target domain room

Agent B works in its own domain room. The handoff thread lives in the source room (where A posted), but B's actual work happens in B's domain.

## Scenario examples

1. **Dev → Infra**: Dev finishes a feature, @mentions infra in `#infra` with a summary. Infra picks up in `#infra`, creates a thread, deploys. Status updates in thread.
2. **Infra → Dev**: Infra detects disk issue, @mentions dev in `#dev` with context. Dev investigates in `#dev`, fixes log retention. Thread tracks progress.
3. **Smart Home → Dev**: Smart home needs custom integration, @mentions dev in `#dev` with requirements. Dev writes code in `#dev`. Thread shows status.
4. **Dev → Smart Home**: API changes affect device schema, dev @mentions smart home in `#home` with details. Smart home updates automations in `#home`.
5. **Architect intervention**: Architect notices in `#infra` that a server change will break dev deployment. Posts in both rooms to coordinate.

## Open questions resolved

1. **Structured messages**: No — natural language
2. **Auto-join**: Ticket 04 decided: agents can invite other agents
3. **Escalation**: Escalate to architect in the same thread
4. **State tracking**: Thread-based with status reactions
5. **Context passing**: Agent A provides summary in the @mention
