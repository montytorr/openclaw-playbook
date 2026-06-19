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
MemoryHigh=2400M
MemoryMax=3200M
MemorySwapMax=512M
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
systemctl --user restart openclaw-gateway.service
systemctl --user show openclaw-gateway.service \
  -p ActiveState -p MainPID -p MemoryCurrent -p MemoryHigh -p MemoryMax -p MemorySwapMax -p Environment -p OOMPolicy
```

If user-systemd commands run from cron or a non-login shell, you may need:

```bash
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus
```

## External Memory Watchdog

Run a small host-level watchdog every few minutes. It should:
- identify the real gateway daemon PID, not `openclaw gateway status`
- read RSS from `/proc/<pid>/status`
- log at a warning threshold
- restart gracefully at a higher threshold when idle
- force a graceful restart at a final threshold if memory keeps growing
- debounce restarts

This belongs in host cron or a systemd timer, not an OpenClaw isolated model cron.

Example cron shape:

```cron
*/2 * * * * root /opt/openclaw/scripts/gateway-memory-guard >/dev/null 2>> /var/log/openclaw/gateway-memory-guard.log || true
```

Verify the guard against concurrent status checks. A sloppy process matcher can accidentally watch the CLI status process instead of the daemon.

## Session Store Pressure

Large session stores create slow startup, expensive status calls, and brittle restart recovery. Treat session cleanup as routine maintenance, not emergency work.

Useful guardrails:
- rotate oversized Discord/session transcripts into an archive directory
- prune stale channel keys that have not been touched in 24h+ unless you intentionally preserve them
- remove stale `.lock`, `.bak-*`, and migrated sidecars after a retention window
- keep a lane-timeout watchdog for sessions that repeatedly exceed worker limits
- restart the gateway only after state cleanup when the lane is wedged

Do not blindly delete active transcripts. Archive first, prune only stale metadata, and log counts.

## Cron Runtime Hygiene

Agent-backed cron jobs are useful for work that needs reasoning. They are a bad place for high-frequency deterministic checks.

Move these to host cron where practical:
- Docker/container health checks
- provider/model status cache refresh
- gateway/session guard summaries
- session-store cleanup
- A2A reactor no-op polling
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
- Codex auth profile inventory is clean
- deterministic watchdogs exit silently on success
- no duplicate OpenClaw cron still performs the same host-level check

## What To Build

- [ ] Add systemd memory limits for the gateway service
- [ ] Add a host-level gateway RSS guard
- [ ] Add session-store rotation/prune maintenance
- [ ] Move deterministic high-frequency cron work out of model-backed cron
- [ ] Add Codex auth profile inventory to health checks
- [ ] Verify Docker bridge reachability from containers
- [ ] Document one post-update reapply/verification wrapper
- [ ] Log incidents with root cause, mitigation, and verification commands

---

*Previous: [Chapter 16 — Infrastructure & Networking](16-infrastructure.md)*
