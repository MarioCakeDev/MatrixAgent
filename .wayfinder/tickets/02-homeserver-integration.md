# Ticket: Homeserver Integration

**Labels**: `wayfinder:research`
**Blocked by**: _(resolved: 01-deployment-target → Coolify worker, appservice mode)_
**Blocks**: 07-zooid-yaml

## Question

How does Zooid connect to the existing Synapse homeserver at `matrix.mariocake.de`?

### Key sub-questions

1. **Registration**: Zooid agents need Matrix user accounts. Does Synapse have `ENABLE_REGISTRATION` on? Or do we need to pre-register accounts via the admin API / Ketesa?
   - The Matrix service has `ENABLE_REGISTRATION` env var — need to check its value.
   - If registration is off, we register agent accounts via Synapse admin API or Ketesa, then configure Zooid with those credentials.

2. **Application Service vs. Client**: 
   - `appservice` mode (push): Synapse pushes events to the daemon. Requires registering an AS on Synapse (a `registration.yaml` file). More robust for always-on setups.
   - `client` mode (pull): Daemon syncs via regular Matrix client API. Simpler setup, no AS registration needed. Works behind firewalls.
   - For a Coolify-hosted setup on the same machine, `appservice` is likely ideal.

3. **Network**: The daemon and homeserver are on the same Coolify worker. Docker networking — can the daemon reach Synapse via its container name or the internal Docker network?
   - The Matrix service is on the `coolify` Docker network. The Zooid daemon would need to join that network.

4. **E2EE**: Zooid agents in encrypted rooms — does the agent handle encryption? The pre-built images likely support it, but need to verify.

5. **Server name**: The homeserver's server name is `mariocake.de` (from `SYNAPSE_SERVER_NAME`). Agent usernames would be `@{workstation}.{agent}:mariocake.de`.

### Research needed

- Read the Zooid docs on transport modes: https://zooid.dev/docs
- Check if Synapse registration is enabled or if we need to pre-register.
- Check the Matrix service's Docker network and how to connect Zooid to it.

## Research findings

### Zooid transport modes
- `appservice` (push): Synapse pushes events to daemon. Needs `as_token`/`hs_token` and registration file. Best for co-located always-on.
- `client` (pull): Daemon fetches events. No inbound needed. Good for laptops/firewalls.

### Synapse + MAS setup
- Synapse runs in the Matrix service on Home Worker 01
- MAS (Matrix Authentication Service) handles auth via OIDC
- MAS admin API is exposed to Ketesa (same Docker network)
- Ketesa has full MAS integration: user creation, session management, etc.

### Network
- Matrix service has `connect_to_docker_network: false`
- Decision: Use external URL `https://matrix.mariocake.de:8008` via Traefik
- Both on same worker, but external URL avoids service config changes

### E2EE
- Zooid does NOT support E2EE yet (declared unsupported on Matrix.org ecosystem)
- Agent rooms will be unencrypted — acceptable for self-hosted server

### Agent accounts
- Create via Ketesa UI (MAS backend)
- Workstation name: `home`
- Agent namespace: `@home.*:mariocake.de`

## Resolution

**Decision: appservice mode, external URL, Ketesa for accounts, unencrypted rooms.**

### Configuration summary

| Setting | Value |
|---------|-------|
| Workstation name | `home` |
| Transport mode | `appservice` (push) |
| Homeserver URL | `https://matrix.mariocake.de:8008` |
| Daemon advertise URL | `http://zooid-daemon:9099` (Docker internal) or external |
| Agent namespace | `@home.*:mariocake.de` |
| Agent accounts | Created via Ketesa UI |
| E2EE | Not supported — unencrypted |
| Runtime | Docker (`ghcr.io/zooid-ai/agent-opencode:latest`) |

### Scripts created

- `scripts/generate-as-registration.sh` — generates AS tokens and registration file
- `scripts/install-registration.sh` — installs registration into Synapse config
- `scripts/verify-integration.sh` — verifies the integration is working

### Deployment steps

1. Run `generate-as-registration.sh` on the worker (generates tokens + registration)
2. Run `install-registration.sh` on the worker (adds to Synapse, restarts)
3. Create agent accounts in Ketesa UI (@home.architect, @home.coding, etc.)
4. Configure Zooid daemon with tokens from `.env` file
5. Start Zooid daemon
6. Run `verify-integration.sh` to confirm

### Unblocked by this decision

- **07 Zooid YAML** — all transport config known
