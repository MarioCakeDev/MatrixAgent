# ADR: Homeserver Integration

**Status:** Accepted  
**Date:** 2026-09-05  
**Deciders:** Mario  
**Ticket:** 02-homeserver-integration

## Context

Zooid needs to connect to the existing Synapse homeserver at `matrix.mariocake.de`. The daemon runs on Home Worker 01 (Coolify worker), same machine as Synapse. We need to decide how they communicate, how agent accounts are created, and whether rooms are encrypted.

## Decision

### Transport: appservice mode via external URL

Use `appservice` mode (push) with the external URL `https://matrix.mariocake.de:8008`. Synapse pushes events to the Zooid daemon.

**Why external URL instead of Docker internal network:**
- Matrix service has `connect_to_docker_network: false`
- Changing this requires modifying the Coolify service config
- External URL works without service config changes
- Traefik handles TLS termination
- Slightly less efficient (goes through proxy) but negligible for agent traffic

### Agent accounts: Ketesa UI

Create agent accounts via Ketesa admin UI, which uses the MAS admin API under the hood.

**Why not direct MAS API:**
- Ketesa already has MAS integration working
- UI is simpler for initial setup
- Auditable via Keteka's interface
- MAS API is exposed only to Ketesa's container on the Docker network

### E2EE: Not supported

Zooid does not implement E2EE yet (declared unsupported on Matrix.org ecosystem). Agent rooms will be unencrypted.

**Why acceptable:**
- This is a self-hosted server — admin has access anyway
- Agent conversations are not more sensitive than regular chat
- E2EE support may come in future Zooid releases
- Encrypted rooms would add key management complexity

### AS registration: Manual with scripts

Create registration.yaml manually using helper scripts. Tokens generated with `openssl rand -hex 32`.

**Why manual:**
- One-time setup, not worth automating
- Scripts handle token generation and file creation securely
- Clear audit trail

## Consequences

### Positive
- Simple setup — no Docker network changes needed
- Ketesa provides UI for account management
- Clear script-based deployment process
- Unencrypted rooms simplify debugging

### Negative
- External URL adds a proxy hop (negligible impact)
- No E2EE means room content visible to server admin
- Manual AS registration requires SSH access to worker

### Risks
- If Traefik is down, daemon can't receive events (mitigated: same machine, local loopback)
- Future Zooid updates might change registration format (mitigated: scripts are simple to update)
