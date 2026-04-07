# OpenClaw Playbook — One-Pager

If you only want the essence, start here.

## The 4-Part Starter Kit

1. **Identity files**
   - `AGENTS.md`
   - `SOUL.md`
   - `USER.md`
   - `TOOLS.md`

2. **Memory**
   - write to `memory/YYYY-MM-DD.md`
   - extract observations into SQLite
   - regenerate `MEMORY.md` as a digest

3. **Task tracking**
   - `task start` before work
   - `task update <id> done` when complete

4. **Timing + enforcement**
   - heartbeat for batched checks
   - cron for exact timing / isolated runs
   - hooks to guard dangerous tool calls

## Minimum Viable Loop

```bash
# 1. Start work
task start "Fix thing" "What was requested" other

# 2. Write memory during work
echo "# 2026-04-04" >> memory/2026-04-04.md
echo "- Fixed issue X because Y" >> memory/2026-04-04.md

# 3. Extract/search memory
reference/scripts/mem-extract
reference/scripts/mem-search "issue X"

# 4. Finish work
task update <id> done "What changed"
```

## Default Model Split (Codex-first)

- Main agent: `gpt-5.4` + `thinking=medium`
- Cron/reactors: `spark` + `thinking=low`
- Mechanical loops: `spark` + `thinking=disabled`
- Sub-agents: `thinking=off` unless reasoning is actually needed

## Brownfield First, If Applicable

If you're adopting this into an already-active setup:
- take a baseline snapshot before changing behavior
- map existing task/memory/hooks surfaces before replacing anything
- prefer archive-first cleanup
- ingest Tier A memory first, not bootstrap noise
- harden hooks in stages: informational -> warning/logging -> blocking
- scope `the-wall` narrowly first: high-confidence hard blocks everywhere, extra scrutiny around A2A, reactors, sub-agent delegation, and external publish paths

Read `playbook/00-brownfield-adoption.md` first.

## A2A in One Line

The good pattern is:

```text
webhook receiver -> durable queue -> a2a-reactor -> side effects
```

Meaning:
- webhook handler verifies HMAC and returns fast
- queue gives durability and replay surface
- reactor handles routing: tasks, notifications, wakeups, replies
- cron fallback cleans up missed wake events

## Validation Quick Checks

- Can the agent write a daily note?
- Can `task list` show current work?
- Can heartbeat wake and return `HEARTBEAT_OK`?
- Can a dangerous tool call be blocked by a hook?
- Can a completed task be found later via memory search?

If yes, you have infrastructure — not just prompts.
