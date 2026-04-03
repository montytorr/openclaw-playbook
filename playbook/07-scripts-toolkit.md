# Chapter 7: Scripts Toolkit

Scripts are your agent's hands. The identity files tell it who it is; the hooks guard what it does; the scripts are how it actually does things. This chapter documents the patterns for each utility script category.

## Philosophy

Scripts should be:
- **CLI-first** — callable from the command line with clear arguments and flags
- **Composable** — each script does one thing; combine them for complex workflows
- **Idempotent** where possible — safe to run multiple times
- **Self-documenting** — `--help` flag on everything
- **Logging** — write to logs/ when actions have side effects

Keep scripts in `scripts/` at the workspace root. Use any language — bash, Python, Node.js — whatever you're comfortable maintaining. The agent calls them via `exec`, so the interface is the command line.

## System Scripts

### `status-report` — System Health Summary

**Purpose:** Single-command health check for your entire stack.

**Interface:**
```bash
# Text output (for Discord/chat)
status-report

# JSON output (for dashboards/automation)
status-report --json

# Specific sections only
status-report --section docker
status-report --section system
```

**What it checks:**
- **System:** CPU, RAM, disk usage, uptime, load average
- **Docker:** container status, restart counts, unhealthy containers
- **Gateway:** OpenClaw gateway process status, uptime
- **Cron:** recent cron job execution status, failures
- **Network:** key service reachability (ping your critical endpoints)

**Output format (text):**
```
🖥️ System Health Report
━━━━━━━━━━━━━━━━━━━
CPU: 23% | RAM: 4.2/8GB (52%) | Disk: 45/100GB (45%)
Uptime: 14d 6h | Load: 0.42 0.38 0.31

🐳 Docker: 5/5 containers healthy
   dashboard: up 3d | gateway: up 14d | traefik: up 14d

⚙️ Gateway: running (pid 1234) | uptime: 14d
🕐 Cron: 8 jobs | last failure: none in 24h
🌐 Network: all endpoints reachable
```

### `integrity-check` — File Integrity Monitoring

**Purpose:** Detect unexpected changes to critical files.

**Interface:**
```bash
# Create baseline (run after intentional edits)
integrity-check init

# Check current state against baseline
integrity-check check

# Show current baseline
integrity-check show
```

**How it works:**
1. `init`: Computes SHA-256 hashes of watched files, stores in `security/integrity-baseline.json`
2. `check`: Recomputes hashes, compares to baseline, reports mismatches

**Watched files** (configurable):
- SOUL.md, AGENTS.md, IDENTITY.md, SECURITY.md
- Any other files you want to monitor

**Baseline format:**
```json
{
  "created_at": "2026-04-03T10:00:00Z",
  "files": {
    "SOUL.md": {
      "hash": "sha256:a1b2c3...",
      "size": 2048,
      "modified": "2026-04-01T15:30:00Z"
    }
  }
}
```

### `propose-edit` / `approve-edit` / `reject-edit` — Protected File Flow

**Purpose:** Controlled modification of read-only files.

**Interface:**
```bash
# Agent proposes an edit (reads new content from stdin)
echo "new content" | propose-edit SOUL.md "Add lesson about verification"

# Human reviews
cat .proposed/SOUL.md.proposed
diff SOUL.md .proposed/SOUL.md.proposed

# Human approves or rejects
approve-edit SOUL.md    # Copies proposed → actual, re-baselines integrity
reject-edit SOUL.md     # Deletes proposed file
```

**Flow:**
1. Agent writes proposed content to `.proposed/<filename>.proposed`
2. Agent shows the diff to the human
3. Human decides
4. On approve: copy proposed to actual, delete proposed, run `integrity-check init`
5. On reject: delete proposed file

## Learning Scripts

### `feedback` — Decision Tracking

**Purpose:** Build a knowledge base of human decisions for pattern detection.

**Interface:**
```bash
# Log a decision
feedback log "agent" "Recommended buying AAPL at $180" "approved" "Good entry point, aligned with thesis"
feedback log "agent" "Suggested refactoring auth module" "rejected" "Too risky before launch"
feedback log "agent" "Proposed new cron schedule" "modified" "Approved with different timing"

# View recent feedback
feedback list
feedback list --days 7

# Analyze mistake patterns
feedback mistakes
feedback mistakes --category trading
```

**Storage:** Weekly JSON files in `feedback/` directory:
```
feedback/
├── 2026-W14.json
├── 2026-W15.json
└── 2026-W16.json
```

**Why it matters:** Over time, patterns emerge. "My trading recommendations get rejected when they're momentum-based during low-volume periods." The `mistakes` view surfaces these patterns so the agent can self-correct.

### `self-critique` — 3-Pass Review System

**Purpose:** Catch mistakes before they happen, not after.

**Interface:**
```bash
# Run critique on a draft
self-critique run trading "Buy AAPL at $180, expecting earnings beat..."

# See the template for a category
self-critique template polymarket

# View critique history
self-critique history
self-critique history --category trading
```

**The 3 passes:**

1. **Criteria Check** — does the draft pass all category-specific criteria?
   - Trading: position sizing, risk/reward ratio, thesis clarity, market conditions
   - Research: source quality, logical consistency, alternative explanations
   - Communication: tone match, brevity, accuracy, audience-appropriateness

2. **Red Flag Scan** — any warning signs?
   - Trading: FOMO language, ignoring sector rotation, over-concentration
   - Research: single-source conclusions, confirmation bias, missing counterarguments
   - Communication: leaked information, tone mismatch, unclear action items

3. **Refinement** — what would you change on second thought?
   - Generates a revised version incorporating findings from passes 1 and 2

**Categories** (configurable): trading, polymarket, email, research, general

### `mem-search` — Observation Search

**Purpose:** Full-text search over the claude-mem SQLite database.

**Interface:**
```bash
# Search by keyword
mem-search "docker restart issue"

# Search with filters
mem-search "trading" --after 2026-03-01 --category decision

# Get specific observations
get-observations 42 43 44
```

Cross-reference: see Chapter 2 for the full memory system.

## Operational Scripts

### `task` — Task Management CLI

The primary task tracking interface. Fully documented in Chapter 3.

```bash
task start "Title" "Input" [category] [priority]
task done "Title" "Input" "Output" [category]
task update <id> <status> "Description"
task list [status]
task search "query"
task sprint
```

### `betterstack-ping` — Heartbeat Monitoring

**Purpose:** Ping external monitoring services to prove your agent is alive.

**Interface:**
```bash
# Ping a named heartbeat
betterstack-ping main-agent
betterstack-ping dashboard
```

**Why:** If your agent stops running, you want to know. External monitoring services (BetterStack, UptimeRobot, etc.) alert you when pings stop arriving.

**Config:** Map heartbeat names to URLs in `config/betterstack-heartbeats.json`:
```json
{
  "main-agent": "<YOUR_HEARTBEAT_URL>",
  "dashboard": "<YOUR_HEARTBEAT_URL>"
}
```

## Building Scripts: Best Practices

1. **Always add `--help`** — your agent will use it when it forgets the interface
2. **Exit codes matter** — 0 for success, non-zero for failure. The agent checks these.
3. **Structured output** — support both human-readable and JSON output where useful
4. **Error messages to stderr** — keep stdout clean for piping
5. **No interactive prompts** — the agent can't type "y" to confirm. Use flags instead.
6. **Idempotent** — `integrity-check init` should be safe to run twice

## What to Build

- [ ] Build `status-report` — system health in one command
- [ ] Build `integrity-check` — file integrity monitoring (init + check)
- [ ] Build `propose-edit` / `approve-edit` / `reject-edit` — protected file flow
- [ ] Build `feedback` — decision tracking with pattern analysis
- [ ] Build `self-critique` — 3-pass review system
- [ ] Build `mem-search` — observation database search
- [ ] Build `task` — task management CLI (see Chapter 3)
- [ ] Build `betterstack-ping` — external heartbeat pings
- [ ] Add `--help` to every script
- [ ] Document each script's interface in TOOLS.md

---

*Previous: [Chapter 6 — Cron Patterns](06-cron-patterns.md) | Next: [Chapter 8 — Dashboard](08-dashboard.md)*
