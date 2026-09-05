# Ticket: Deployment Target

**Labels**: `wayfinder:research`
**Blocked by**: _(none — this is the first ticket)_
**Blocks**: 02-homeserver-integration, 03-agent-roster, 07-zooid-yaml

## Question

Where should the Zooid daemon run? This is the first decision — everything else depends on it.

**Option A: Coolify worker (Home Worker 01)**
- Pro: Already runs Matrix stack, Docker, and 22 services. Single network.
- Pro: Always-on, no need to keep maripop running.
- Con: The worker is a headless server — agent workdirs would need to be on its disk or mounted remotely.
- Con: Agent containers compete for resources with existing services.
- Question: Can the worker reach maripop's filesystem for agent persona files? (NFS, sshfs, or copy?)

**Option B: maripop (desktop PC)**
- Pro: Agent workdirs live locally — same AGENTS.md, skills, MCP servers as your local opencode.
- Pro: More compute power (desktop vs. worker).
- Con: PC must be on for agents to respond. Sleep/suspend breaks availability.
- Con: Daemon needs to reach the homeserver (easy on LAN, but network mode matters).

**Option C: Both — workstation model**
- Pro: maripop runs local agents (quick dev iteration), Coolify runs production/always-on agents.
- Con: Two daemons to manage, two sets of agent identities.
- Con: Complexity of shared rooms across workstations.

**Recommendation**: Option A (Coolify worker) for reliability, with the agent workdir either on the worker's disk (synced from maripop via a simple rsync/copy) or on a shared volume. maripop can still use the Matrix rooms as a client.

### Research findings

**Resources:**
- Worker (Home Worker 01): 8 CPUs, 27.6 GB RAM (~15 GB available), 252 GB disk (42 GB free, 83% used)
- maripop: 16 CPUs, 62 GB RAM (~48 GB available), 738 GB disk (252 GB free, 65% used)
- Docker on worker: 220 GB total, 163 GB volumes, 29 GB images, ~24 GB reclaimable

**Zooid architecture:**
- `runtime: docker` — each agent gets its own container
- `workdir` is auto-mounted into container at `/workspace`
- Preset state (`~/.local/share/opencode`, `~/.config/opencode`) auto-mounted for auth
- Additional mounts via `container.mounts` (host path → container path)
- `appservice` mode: homeserver pushes events to daemon (needs reachable address)
- `client` mode: daemon fetches events (no inbound needed, good for firewalls)
- Multiple workstations can share one homeserver (each needs own AS registration)

**Network:**
- Worker and Synapse are on the same Docker network (`coolify`)
- Daemon can advertise `localhost:9099` or use Docker network addressing

## Resolution

**Decision: Option A — Coolify worker (Home Worker 01), with `appservice` mode.**

**Rationale:**
1. **Always-on** — agents respond 24/7, no dependency on desktop sleep/suspend
2. **Same network as Synapse** — both on `coolify` Docker network, no cross-host networking needed
3. **`appservice` mode** — homeserver pushes to daemon, most efficient for co-located always-on setup
4. **Disk is manageable** — 42 GB free, agent containers are small (~200-500 MB images), workdirs bind-mount from host (no copy needed). ~24 GB reclaimable from unused volumes if needed.
5. **RAM sufficient** — 15 GB available, daemon + 5 agent containers likely use 2-4 GB total

**Workdir strategy:**
- Agent persona files (AGENTS.md, skills, MCP configs) live on the worker's disk
- Project workdirs bind-mount from the worker's filesystem
- For projects that live on maripop: either sync to worker via rsync, or use `container.mounts` with NFS/sshfs if needed
- OpenCode preset state (`~/.local/share/opencode`, `~/.config/opencode`) must exist on the worker — run `opencode auth login` once on the worker to bootstrap

**Future option:** Add maripop as a second workstation later (powerful desktop for dev iteration, `client` mode since it's remote from the homeserver). Both workstations share the same Matrix rooms.

### Unblocked by this decision

- **02 Homeserver Integration** — daemon runs on same machine as Synapse, `appservice` mode, localhost:9099
- **03 Agent Roster** — workdirs on worker's disk, one container per agent
- **07 Zooid YAML** — `runtime: docker`, `mode: appservice`, workstation name needed
