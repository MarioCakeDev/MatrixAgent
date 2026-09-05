# MCP setup — installed servers and configuration

Reference for the `infrastructure` skill's Control section. Updated 2026-08-31
with five new MCP servers replacing manual SSH/REST calls.

## Fixed issues (2026-08-31)

1. **coolify-rw**: Env var was `COOLIFY_URL`, should be `COOLIFY_BASE_URL`
2. **truenas**: SSL verify bug in truenas-mcp-server (verify on client vs transport) — patched locally
3. **ssh**: Invalid `approvalPolicy = "ask"` → `"ask-destructive"` (valid: auto, ask-destructive, ask-all, deny)

## Installed MCP servers

### 1. Coolify (built-in, read-only) — `coolify`

- **Type**: Remote (Streamable HTTP)
- **URL**: `https://coolify.mariocake.de/mcp`
- **Auth**: Bearer token from `~/.config/opencode/secrets/coolify-token`
- **When**: Quick status checks, listing resources, reading logs
- **Key tools**: `get_infrastructure_overview`, `list_unhealthy_resources`, `get_logs`, `list_deployments`, `get_application`, `list_applications`

### 2. Coolify RW (StuMason) — `coolify-rw`

- **Type**: Local (stdio)
- **Command**: `coolify-mcp`
- **Environment**: `COOLIFY_BASE_URL=https://coolify.mariocake.de`, `COOLIFY_ACCESS_TOKEN` from file
- **When**: Deploying, restarting, updating compose, creating/deleting apps
- **Key tools**: `deploy_application`, `restart_application`, `update_service_compose`, `create_application`, `diagnose_app`
- **Safety**: Destructive ops require human confirmation via elicitation
- **Install**: `npm install -g @masonator/coolify-mcp`
- **Note**: Server expects `COOLIFY_BASE_URL`, not `COOLIFY_URL`

### 3. Home Assistant — `ha`

- **Type**: Local (stdio)
- **Command**: `ha-mcp`
- **Environment**: `HA_MCP_URL=https://hass.lan:8123`, `HA_MCP_TOKEN` from file, `HA_MCP_TIMEZONE=Europe/Berlin`
- **When**: Querying device states, calling services, managing automations
- **Key tools**: `get_states`, `get_state`, `call_service`, `list_entities`, `list_services`, `fire_event`
- **Token source**: Extracted from lnxlink config (`home_assistant.token`), stored at `~/.config/opencode/secrets/ha-token`
- **Install**: `npm install -g ha-mcp`

### 4. Docker (local) — `docker`

- **Type**: Local (stdio)
- **Command**: `mcp-docker-server`
- **When**: Managing local containers on maripop (lnxlink, aniworld-downloader)
- **Key tools**: List/start/stop/restart containers, list images, manage volumes
- **Note**: For Coolify server containers, use the Coolify MCP instead
- **Install**: `npm install -g mcp-docker-server`

### 5. SSH — `ssh`

- **Type**: Local (stdio)
- **Command**: `ssh-mcp`
- **Config**: `~/.config/ssh-mcp/config.toml`
- **When**: Remote shell access to coolify.lan, truenas.lan, router.lan
- **Profiles**: `coolify` (192.168.1.92), `truenas` (192.168.1.55), `router` (192.168.1.1)
- **Safety**: All destructive commands require human approval (`approvalMode = "ask-destructive"`)
- **Install**: `npm install -g ssh-mcp`

### 6. TrueNAS — `truenas`

- **Type**: Local (stdio)
- **Command**: `truenas-mcp-server`
- **Environment**: `TRUENAS_URL=https://truenas.mariocake.de`, `TRUENAS_API_KEY` from file, `TRUENAS_VERIFY_SSL=true`
- **When**: Checking backup status, storage pools, datasets, snapshots
- **Key tools**: System info, storage pools, datasets, snapshots, SMB shares
- **Status**: Working (URL switched 2026-08-31 to LE-cert hostname, verify on)
- **Install**: `pipx install truenas-mcp-server`
- **Note**: Patched SSL verify bug — `verify` must be on transport, not client (patch confirmed still present in venv 2026-08-31). Re-run `pipx install truenas-mcp-server` will lose patch. TrueNAS 25.04 deprecates the REST API this server uses — may break on future TrueNAS major upgrade.

### 7. Playwright — `playwright`

- **Type**: Local (stdio)
- **Command**: `npx -y @playwright/mcp@latest --headless --device "Pixel 9 Pro"`
- **When**: Headless browser automation, mobile screenshots, web testing

## Secrets

All secrets stored in `~/.config/opencode/secrets/` (0600), referenced via
`{file:...}` so values never enter agent context:

| File | Content | Source |
|------|---------|--------|
| `coolify-token` | Coolify API token (read+write scope) | Coolify UI → Settings → API |
| `ha-token` | Home Assistant long-lived token | Extracted from lnxlink config |
| `truenas-api-key` | TrueNAS API key | TrueNAS UI → Settings → API Keys |

## HA token rotation

The REST route `POST /auth/long_lived_access_token` returns 404 on current HA.
Create new tokens **via WebSocket**:

```bash
# Use wscat or a script — never load token into agent context
wscat -c "wss://hass.lan:8123/api/websocket"
# Send: {"type": "auth", "access_token": "<existing_token>"}
# Send: {"id": 1, "type": "auth/long_lived_access_token", "client_name": "lnxlink", "lifespan": 365}
```

Old tokens are revoked in the HA UI (Profile → Security → Long-lived tokens).

## Not bundleable today

- `mcp-remote` is not on PATH and `~/.mcp-auth` dirs are empty.
- The ngrok `mcp_proxy` on `:9090` is inert (SSE, not running).
- Ollama is absent on the server (despite the `ollama.coolify.lan` DNS name).
