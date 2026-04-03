# Chapter 6: Cron Patterns

Your agent has two timing mechanisms: heartbeats and cron jobs. Knowing when to use each is the difference between an efficient system and a token-burning mess.

## Heartbeats vs Cron: The Decision Tree

```
Need exact timing? (9:00 AM sharp, every Monday at noon)
  → YES → Use cron
  → NO ↓

Need isolation? (different model, no main session history)
  → YES → Use cron
  → NO ↓

Can batch with other checks? (email + calendar + weather in one pass)
  → YES → Use heartbeat
  → NO ↓

One-shot reminder? ("remind me in 20 minutes")
  → YES → Use cron
  → NO → Use heartbeat
```

### Heartbeat: The Batched Approach

Heartbeats are periodic polls to the main session. The agent wakes up, reads HEARTBEAT.md, runs through a checklist, and either acts or says "HEARTBEAT_OK."

**Best for:**
- Multiple checks that batch together (inbox + calendar + notifications = one turn)
- Tasks that need conversational context from recent messages
- Timing that can drift (every ~30 min is fine, exact minute doesn't matter)
- Reducing total API calls by combining checks

**Limitations:**
- Runs in the main session (contributes to context size)
- Timing is approximate (OpenClaw's heartbeat interval, not exact)
- Can't use a different model or thinking level

### Cron: The Precision Approach

Cron jobs fire at exact times and run in isolated sessions by default.

**Best for:**
- Exact schedules ("9:00 AM Paris time every weekday")
- Tasks that need isolation from main session history
- Different model or thinking level for specific tasks
- One-shot reminders ("remind me at 3pm")
- Output that delivers directly to a channel without main session involvement
- Heavy processing that would bloat main session context

**Cost:** Each cron job is a separate session = separate API call with its own context load.

## Cron Job Configuration

### Payload Types

| Payload Kind | Behavior |
|------|----------|
| `systemEvent` | Fires into the main session (like a heartbeat but at exact time) |
| `agentTurn` | Fires into an isolated session (independent context) |

### Session Targeting

| `sessionTarget` | Description |
|--------|-------------|
| `main` | The agent's main session |
| `isolated` | A fresh isolated session (default for agentTurn) |

### Schedule Kinds

| Kind | Fields | Description |
|------|--------|-------------|
| `cron` | `expr`, optional `tz` | Standard cron expression with optional timezone |
| `every` | `everyMs`, optional `anchorMs` | Interval-based (every N milliseconds) |
| `at` | `at` (ISO timestamp) | One-shot at a specific time |

### Delivery Options

| Mode | Description |
|--------|-------------|
| (omitted) | No output delivery (fire and forget) |
| `announce` | Deliver output to a specific channel (Discord, Telegram, etc.) |

### Example Cron Configurations

**Morning briefing (weekdays at 8:30 AM):**
```json
{
  "id": "morning-brief",
  "name": "Morning Briefing",
  "enabled": true,
  "schedule": {
    "kind": "cron",
    "expr": "30 8 * * 1-5",
    "tz": "<YOUR_TIMEZONE>"
  },
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "Generate a morning briefing: check calendar for today's events, scan email for anything urgent, check market pre-open for any positions that need attention. Deliver a concise summary.",
    "model": "anthropic/claude-sonnet-4-6",
    "timeoutSeconds": 600
  },
  "delivery": {
    "mode": "announce",
    "channel": "<YOUR_CHANNEL_ID>"
  }
}
```

**Nightly system health check (daily at 2 AM):**
```json
{
  "id": "nightly-health",
  "name": "Nightly Health Check",
  "enabled": true,
  "schedule": {
    "kind": "cron",
    "expr": "0 2 * * *",
    "tz": "UTC"
  },
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "Run system health check: Docker containers, disk space, cron job status, recent error logs. Only report if something needs attention.",
    "model": "<CHEAPER_MODEL>",
    "timeoutSeconds": 300
  },
  "delivery": {
    "mode": "announce",
    "channel": "<YOUR_CHANNEL_ID>"
  }
}
```

**Integrity monitoring (every 6 hours):**
```json
{
  "id": "integrity-check",
  "name": "Integrity Monitor",
  "enabled": true,
  "schedule": {
    "kind": "cron",
    "expr": "0 */6 * * *"
  },
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "Run integrity-check. If any files have unexpected changes, report immediately. Otherwise, stay silent.",
    "timeoutSeconds": 300
  },
  "delivery": {
    "mode": "announce",
    "channel": "<YOUR_SECURITY_CHANNEL_ID>"
  }
}
```

**One-shot reminder (using "at" schedule):**
```json
{
  "id": "reminder-abc123",
  "name": "Deployment Reminder",
  "enabled": true,
  "schedule": {
    "kind": "at",
    "at": "2026-04-03T15:00:00Z"
  },
  "sessionTarget": "main",
  "payload": {
    "kind": "systemEvent",
    "text": "Remind: the deployment window opens in 1 hour. Review the checklist."
  }
}
```

**Weekly cost report (Mondays at 9 AM):**
```json
{
  "id": "weekly-cost-report",
  "name": "Weekly Cost Report",
  "enabled": true,
  "schedule": {
    "kind": "cron",
    "expr": "0 9 * * 1",
    "tz": "<YOUR_TIMEZONE>"
  },
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "Generate weekly LLM cost report from observer logs. Compare to last week. Highlight any unusual spending patterns.",
    "timeoutSeconds": 600
  },
  "delivery": {
    "mode": "announce",
    "channel": "<YOUR_CHANNEL_ID>"
  }
}
```

## HEARTBEAT.md Configuration

Keep this file small — it's read on every heartbeat, and tokens add up.

```markdown
# HEARTBEAT.md

## Policy
- Check 2-4 things per heartbeat, rotate through the full list
- Respect quiet hours: 23:00-07:00 local time
- If nothing needs attention: reply HEARTBEAT_OK
- Don't repeat checks done <30 minutes ago

## Checklist
- [ ] Email: any urgent unread messages?
- [ ] Calendar: events in next 24h?
- [ ] System: any Docker containers down?
- [ ] Tasks: any stale in-progress tasks (>24h)?

## Commands
- /status → run status-report, post to channel
- /tasks → task list in-progress, summarize
```

The checklist drives heartbeat behavior. Add or remove items as needed. The agent reads this file, checks what's been done recently (via `memory/heartbeat-state.json`), and handles the next items.

## Anti-Patterns

### ❌ Too Many Crons
Each cron job costs tokens. 20 cron jobs firing hourly = 480 sessions/day. Batch related checks into heartbeats instead.

### ❌ Cron Jobs That Need Context
If a cron job needs to know what the agent was doing earlier today, it's fighting against isolation. Use `systemEvent` type (main session) or batch it into a heartbeat.

### ❌ Heartbeats That Never Rest
If every heartbeat does heavy processing, you're burning tokens for checking. Most heartbeats should be `HEARTBEAT_OK`. Structure the checklist so only items due for checking are checked.

### ❌ Duplicate Checking
Don't have a cron job AND a heartbeat checking the same thing. Pick one mechanism per check.

## Cost Optimization

| Strategy | Savings |
|----------|---------|
| Use cheaper models for routine crons | 50-80% per job |
| Batch checks into heartbeats | Fewer total sessions |
| "Only report if something needs attention" | Shorter outputs |
| Increase heartbeat interval during quiet hours | Fewer overnight checks |
| Use `once: true` for reminders | No recurring cost |

## What to Build

- [ ] Set up HEARTBEAT.md with your initial checklist
- [ ] Create `memory/heartbeat-state.json` for check tracking
- [ ] Configure 2-3 essential cron jobs (morning briefing, nightly health, integrity)
- [ ] Define quiet hours in your heartbeat configuration
- [ ] Set up cost tracking for cron jobs (via `llm-observer` hook)
- [ ] Review and optimize after one week of operation
- [ ] Document your cron jobs in `config/` for reference

---

*Previous: [Chapter 5 — Security](05-security.md) | Next: [Chapter 7 — Scripts Toolkit](07-scripts-toolkit.md)*
