# ADR: Cross-Domain Handoffs

**Status:** Accepted  
**Date:** 2026-09-05  
**Deciders:** Mario  
**Ticket:** 06-cross-domain-coordination

## Context

Agents operate in domain-specific rooms (#dev, #infra, #home) but need to request work from other domains. We need a coordination mechanism that provides context locality, status tracking, and conflict resolution without adding infrastructure complexity.

## Decision

### Handoff mechanism: Direct @mentions in domain rooms

Agent A @mentions agent B in B's domain room with a natural-language summary of what's needed. No structured templates — plain language keeps things flexible.

**Why not a dedicated #handoffs room:**
- Ticket 04 already decided agents are scoped to domain + handoffs
- @mentions in domain rooms keep context where it's relevant
- #handoffs room exists in the space structure but is for ad-hoc coordination, not the primary handoff mechanism

**Why not orchestrator-mediated routing:**
- Adds a bottleneck for every cross-domain request
- Orchestrator's role is conflict detection, not routing

### State tracking: Thread-based with status reactions

Each handoff gets a Matrix thread. Status tracked via reactions:
- 🔵 OPEN — request received
- 🟡 IN PROGRESS — agent working on it
- 🟢 DONE — completed

**Why threads over fire-and-forget:**
- Provides visibility into pending work
- Thread keeps status updates colocated with the request
- No separate status room or tracking system needed

### Escalation: To orchestrator in the same thread

If agent B can't handle a request, it @mentions the orchestrator in the same handoff thread. Orchestrator evaluates and routes or resolves.

### Orchestrator: Active monitoring

Orchestrator joins all domain rooms and proactively monitors for cross-domain conflicts. Not limited to escalation-only — can intervene when it detects issues.

## Consequences

### Positive
- Context stays in domain rooms where it's relevant
- Thread-based tracking provides visibility without extra infrastructure
- Natural language keeps handoffs flexible and human-readable
- Orchestrator's active monitoring catches conflicts early

### Negative
- Agents need to be in multiple rooms to participate in cross-domain work
- Thread management adds slight overhead to handoffs
- Orchestrator's active monitoring increases its context load

### Risks
- If handoff volume grows, thread-based tracking may become unwieldy (mitigated: current scale is 5 agents)
- Orchestrator's active monitoring may miss conflicts in rooms it doesn't visit frequently (mitigated: joins all domain rooms)
