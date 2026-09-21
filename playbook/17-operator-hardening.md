# Chapter 17: Operator Hardening

The first version of an autonomous agent stack proves the loop works. The production version survives the boring failures: memory pressure, stale sessions, provider drift, cron spam, bridge firewall drift, and package updates that overwrite local assumptions.

This chapter is the "keep it alive for weeks" layer.

## Design Principle

Model-backed agents are good at judgement. They are expensive and fragile as high-frequency watchdogs.

Put hard operational guarantees outside the model loop:
- systemd resource limits
- host cron or systemd timers for deterministic checks
- small scripts that exit silently on success
- logs with enough context to debug later
- explicit post-update verification

The agent can still summarize, decide, and escalate. It should not be the only thing standing between a leaking gateway and a host-wide OOM kill.

## Gateway Memory Guardrails

Long-lived Node gateway processes can grow steadily under memory extraction, session pressure, plugin load, or log churn. If the gateway gets killed by the kernel OOM killer, every active Discord or webhook turn may become an orphaned session and users see "interrupted by a gateway restart" recovery notices.

Use two layers:

1. **systemd limits** to contain blast radius
2. **external RSS guard** to restart cleanly before kernel OOM

Example user-service drop-in:

```ini
# ~/.config/systemd/user/openclaw-gateway.service.d/40-memory.conf
[Service]
Environment=NODE_OPTIONS=--max-old-space-size=1536
MemoryHigh=4G
MemoryMax=5G
MemorySwapMax=1G
OOMPolicy=stop
OOMScoreAdjust=100
```

Tune the numbers for your host. The important pattern is:
- cap V8 heap before it can consume the host
- cap the service cgroup below total RAM
- limit swap so a leak does not pin the machine for minutes
- let systemd restart the service predictably

Apply and verify:

```bash
systemctl --user daemon-reload
/opt/openclaw/scripts/gateway-restart-safe --reason "apply memory limits" --defer
systemctl --user show openclaw-gateway.service \
  -p ActiveState -p MainPID -p MemoryCurrent -p MemoryHigh -p MemoryMax -p MemorySwapMax -p Environment -p OOMPolicy
```

On a chat-critical host, the restart wrapper is not cosmetic. It should queue the request, wait for active runs to drain, and let an external owner perform the restart. Direct restart commands issued from the agent turn being interrupted can kill their own acceptance check.

If user-systemd commands run from cron or a non-login shell, you may need:

```bash
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus
```

## External Memory Watchdog

Run a small host-level watchdog every few minutes. It should:
- identify the real gateway daemon PID, not `openclaw gateway status`
- read RSS from `/proc/<pid>/status`
- read the whole service cgroup memory from systemd, not only the gateway PID RSS
- probe `http://127.0.0.1:18789/health` with a short timeout
- log at a warning threshold
- restart gracefully at a higher threshold only when the gateway is confirmed idle
- force a graceful restart only at a final memory threshold
- treat gateway status timeouts as unknown activity, not as proof the gateway is idle
- log `/health` failures by default; do not make health-only failures restart the gateway unless the operator explicitly opts in
- debounce all restart paths

This belongs in host cron or a systemd timer, not an OpenClaw isolated model cron.

Example cron shape:

```cron
*/2 * * * * root /opt/openclaw/scripts/gateway-memory-guard >/dev/null 2>> /var/log/openclaw/gateway-memory-guard.log || true
```

Verify the guard against concurrent status checks. A sloppy process matcher can accidentally watch the CLI status process instead of the daemon.

Also verify it catches sidecar pressure. Some gateway failures come from `openclaw-hooks`, embedded runtime workers, or other child processes inside the service cgroup. The Node gateway PID can look modest while `MemoryCurrent` for the service is already near `MemoryHigh`. Size the service cgroup for those sidecars. A cap that only fits the gateway Node heap can create avoidable restarts during normal hook-heavy recovery work.

Do not restart on `/health` timeouts alone unless the operator has made that tradeoff explicitly. Short stalls can happen during channel probes, Codex app-server startup, hook sidecar bursts, or Discord recovery. A useful guard logs unhealthy samples and restarts only for confirmed idle pressure or hard memory thresholds. Otherwise the guard becomes the source of the user-facing "interrupted by a gateway restart" notices it was meant to prevent.

## Guarded Restart Ownership

Treat a gateway restart as a small deployment with an owner and an acceptance gate.

A production restart guard should:
- record the reason and requester before touching the service
- defer while a real channel/agent run is active
- bound the active-run fence so a dead run cannot pin the channel forever
- debounce repeated requests so several alerts collapse into one restart
- provide an explicit operator override for a known-safe maintenance window
- let an external systemd/host worker perform the restart, not the foreground chat turn
- verify service owner, main PID, gateway health, channel connectivity, and provider/runtime health afterward

The bounded fence matters. An unbounded "active" marker converts one hung run into a permanently unrestartable gateway. The override matters too, but it should be operator-only and visible in the audit log.

Example request shape:

```bash
/opt/openclaw/scripts/gateway-restart-safe --reason "validated config change" --defer
```

Only report the restart complete after the post-restart checks pass. A queued request is not a restart, and a new PID is not proof that the channel/runtime path is usable.

Useful live probes:

```bash
systemctl --user show openclaw-gateway.service \
  -p MainPID -p MemoryCurrent -p MemoryPeak -p MemoryHigh -p MemoryMax -p MemorySwapMax
curl -m 5 -fsS http://127.0.0.1:18789/health
```

If `/health` times out, treat the gateway as wedged even if the process still exists.

## Discord Restart Recovery

Discord "not reacting" can be a symptom of a wedged gateway, not a Discord token or intent problem.

The pattern to check:
- `openclaw channels status --deep --probe` hangs or reports stale transport
- `openclaw message read --channel discord ...` hangs
- gateway `/health` times out
- restart recovery creates `running` tasks for old Discord sessions
- logs show stale transcript locks or interrupted main-session recovery

Recovery sequence:

```bash
openclaw tasks list --status running --json
openclaw tasks cancel <task-id-or-run-id>
openclaw tasks maintenance --apply
openclaw channels status --deep --probe
openclaw message read --channel discord --target channel:<CHANNEL_ID> --limit 3
```

If a Discord channel session is wedged behind a dead recovery turn, archive the affected transcript and remove only that session key from the session store. Do not delete the whole store. After reset, request a guarded restart and verify the channel audit is clean.

Also keep enabled Discord channel IDs current. A channel audit can fail on stale `Unknown Channel` entries even when the live listener works.

## Session Store Pressure

Large session stores create slow startup, expensive status calls, and brittle restart recovery. Treat session cleanup as routine maintenance, not emergency work.

Useful guardrails:
- rotate oversized Discord/session transcripts into an archive directory
- prune stale channel keys that have not been touched in 24h+ unless you intentionally preserve them
- remove stale `.lock`, `.bak-*`, and migrated sidecars after a retention window
- keep a lane-timeout watchdog for sessions that repeatedly exceed worker limits
- request a guarded restart only after state cleanup when the lane is wedged

Do not blindly delete active transcripts. Archive first, prune only stale metadata, and log counts.

## Memory Health Under Session Pressure

Memory timeouts can be a secondary symptom of session-store pressure rather than a
broken embedding or search backend. Large transcript databases, synchronous session
writes, and overlapping deep probes can block the gateway event loop long enough to
make Discord look dead.

Recovery and prevention pattern:

1. Measure the session-store size, indexed-entry count, write latency, and gateway
   event-loop/health latency.
2. Stop duplicate probes and background jobs that are querying the same memory path.
3. Keep transcript indexing out of the live memory path unless it has a measured
   resource budget; archive transcripts for selective or offline recall instead.
4. Align the runtime cache/index cap with the cap enforced by the health check.
5. Run one clean deep check, then a repeat, and verify gateway/channel liveness
   after both passes.

Record the timings and counts with the incident. “The command eventually finished”
is not a stable health signal if it routinely consumes the gateway's responsiveness
budget.

## Cron Runtime Hygiene

Agent-backed cron jobs are useful for work that needs reasoning. They are a bad place for high-frequency deterministic checks.

Move these to host cron where practical:
- Docker/container health checks
- provider/model status cache refresh
- gateway/session guard summaries
- session-store cleanup
- A2A recovery sweeps whose no-op path is deterministic
- system security scans that run fixed shell commands

Leave these in OpenClaw only when they need synthesis:
- memory extraction/synthesis
- weekly reviews
- human-facing briefings
- triage that requires judgement

After moving a job, disable the duplicate OpenClaw cron. Duplicate checking creates false incidents and unnecessary model spend.

## Codex Auth Drift

OAuth-backed Codex profiles can fail in ways that look like model or quota problems. One real failure pattern is copying a rotating refresh token into multiple profiles or embedded bridge homes. The profiles then invalidate each other.

Hygiene rules:
- keep one canonical profile per account
- remove obsolete `default` profiles after migration
- sync embedded bridge homes from the canonical profile only
- verify auth inventory after OpenClaw updates
- check provider status from OpenClaw, not from an old Anthropic-only or generic cooldown file

Your health script should answer:
- which Codex profile is canonical
- whether any duplicate profile still exists
- whether provider status is usable
- whether the app-server approval policy matches intent

## Docker Bridge Drift

Container-to-host traffic is a common hidden dependency. A host can pass `openclaw gateway status` while containers still time out against the gateway.

Verification should include:

```bash
docker network inspect <YOUR_NETWORK>
docker exec <APP_CONTAINER> curl -fsS http://<HOST_BRIDGE_IP>:18789/health
iptables -S ufw-before-input | grep -- '--dport 18789'
```

If firewall config exists but live rules are absent, reload UFW and verify the live chain again. Treat the live iptables chain as truth.

## Post-Update Reapply Path

Package updates can overwrite assumptions.

Keep one documented update wrapper that:
- backs up current config
- runs the OpenClaw update
- reapplies local drop-ins or compatibility patches
- runs auth sync/health checks
- verifies gateway status, model/provider status, memory status, and bridge reachability
- reports drift instead of silently continuing

The wrapper should be boring and repeatable. Tribal memory is not a recovery plan.

## Privilege Boundaries And Checkout Ownership

Do not let privileged agent processes casually work inside a human-owned checkout. The failure is subtle: read-only Git commands continue to work while root-owned objects, refs, caches, or lockfiles make the next human commit or fetch fail.

Use this order of preference:

1. Root/privileged agents work in root-owned clones or worktrees under an agent-owned project root.
2. A worker that must touch a human-owned checkout runs under that human's UID in a sandbox with an explicit writable path.
3. If a runner must traverse a privileged parent directory, grant only the minimum execute/traverse ACL, monitor the ACL mask, and audit who changes it.

Do not normalize recursive `chown` as maintenance. It repairs the symptom and guarantees the incident returns.

Cheap regression probes catch the problem early:

```bash
git -C <HUMAN_OWNED_REPO> hash-object -w --stdin </dev/null
find <HUMAN_HOME> -xdev -user root -print
```

Run the ownership scan with scoped exclusions for intentionally privileged files. Alert on new drift rather than repeatedly rewriting ownership. If CI only needs a repository under a privileged path, moving the runner-owned checkout to `/srv` or another neutral service root is usually cleaner than depending on `/root` traversal forever.

## Verification Checklist

Run these after hardening changes and after OpenClaw updates:

```bash
openclaw gateway status --deep
openclaw memory status --deep
openclaw status --json
systemctl --user show openclaw-gateway.service \
  -p ActiveState -p MainPID -p MemoryCurrent -p MemoryHigh -p MemoryMax -p MemorySwapMax -p Environment -p OOMPolicy
```

Also verify your own host-level checks:

```bash
/opt/openclaw/scripts/gateway-memory-guard --dry-run
/opt/openclaw/scripts/cron-runtime-watchdog
docker exec <APP_CONTAINER> curl -fsS http://<HOST_BRIDGE_IP>:18789/health
```

Expected:
- gateway connectivity is OK
- memory search is not dirty or paused unexpectedly
- gateway has finite memory/swap limits
- gateway `/health` responds quickly
- service cgroup memory is below warning/restart thresholds
- health-only restart behavior is disabled by default or explicitly opt-in
- active work is never restarted merely because a grace timer elapsed
- restart requests are externally owned, debounced, and protected by a bounded active-run fence
- post-restart service ownership and channel/runtime health are verified
- Codex auth profile inventory is clean
- Discord channel status is connected and audit-clean if Discord is part of the deployment
- deterministic watchdogs exit silently on success
- no duplicate OpenClaw cron still performs the same host-level check

For multi-root workspaces, also verify the integrity contract:

- designate one runtime-canonical root
- compare compatibility mirrors byte-for-byte for every mirrored instruction file
- verify the protected-file hash baseline, including protected files that are not
  safe to print
- run the repository integrity checker after reconciliation

The baseline proves content integrity; the mirror comparison proves that the agent
will receive the same instructions regardless of which supported root is loaded.

## What To Build

- [ ] Add systemd memory limits for the gateway service
- [ ] Add a host-level gateway service-memory/RSS/health guard
- [ ] Add session-store rotation/prune maintenance
- [ ] Add a Discord restart-recovery cleanup runbook if Discord is enabled
- [ ] Add a guarded/deferred restart owner with bounded active-run fencing and post-restart acceptance checks
- [ ] Move deterministic high-frequency cron work out of model-backed cron
- [ ] Add Codex auth profile inventory to health checks
- [ ] Verify Docker bridge reachability from containers
- [ ] Document one post-update reapply/verification wrapper
- [ ] Separate privileged agent worktrees from human-owned checkouts and monitor ownership drift
- [ ] Log incidents with root cause, mitigation, and verification commands

---

*Previous: [Chapter 16 — Infrastructure & Networking](16-infrastructure.md)*
