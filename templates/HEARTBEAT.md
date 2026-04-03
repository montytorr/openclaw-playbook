# HEARTBEAT.md

## Policy
- Check 2-4 items per heartbeat, rotating through the full checklist
- Respect quiet hours: <!-- e.g., 23:00-07:00 --> local time
- If nothing needs attention: reply HEARTBEAT_OK
- Don't repeat checks done less than 30 minutes ago
- Track check timestamps in `memory/heartbeat-state.json`

## Checklist
<!-- Uncomment and customize the checks you want -->
<!-- - [ ] Email: any urgent unread messages? -->
<!-- - [ ] Calendar: events in next 24h? -->
<!-- - [ ] System: any Docker containers down? Disk space OK? -->
<!-- - [ ] Tasks: any stale in-progress tasks (>24h)? -->
<!-- - [ ] Weather: relevant if human might go out? -->
<!-- - [ ] Git: any repos with uncommitted changes? -->
<!-- - [ ] Monitoring: any alerts from external services? -->

## Commands
<!-- Define command handlers the agent should respond to during heartbeats -->
<!-- /status → run status-report, post summary -->
<!-- /tasks → list in-progress tasks, summarize -->
<!-- /health → Docker + system health check -->

## When to Reach Out
- Important email or message arrived
- Calendar event coming up (<2h)
- System health issue detected
- It's been >8h since any interaction

## When to Stay Quiet
- Quiet hours (unless urgent)
- Human is clearly busy
- Nothing new since last check
- Last check was <30 minutes ago
