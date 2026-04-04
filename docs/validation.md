# Validation Guide

A playbook is only useful if you can prove the loop works.

## 1. Workspace bootstraps correctly

```bash
./setup.sh
ls AGENTS.md SOUL.md USER.md TOOLS.md SECURITY.md
ls config/openclaw.example.json
```

Expected:
- identity files exist
- config skeleton exists under `config/`

## 2. Task tracking works

```bash
WORKSPACE_ROOT=$(pwd) reference/scripts/task start "Validation task" "Smoke test" other
WORKSPACE_ROOT=$(pwd) reference/scripts/task list
```

Expected:
- a task id is printed
- the task appears as `in-progress`

## 3. Memory extraction works

```bash
mkdir -p memory
echo '# 2026-04-04

## 10:00 — Validation
- Decided to keep heartbeat checks lean.
- Fixed a startup path mismatch in setup.sh.' > memory/2026-04-04.md
WORKSPACE_ROOT=$(pwd) reference/scripts/mem-extract
WORKSPACE_ROOT=$(pwd) reference/scripts/mem-search "heartbeat"
```

Expected:
- extractor completes
- search returns the stored observation

## 4. Hook skeleton behaves as expected

Read `reference/hooks/the-wall.example.ts` and adapt it into your hook runtime.

Expected behavior:
- a tool call containing a fake secret is blocked
- a normal read/search call is allowed
- a destructive exec pattern is blocked or escalated

## 5. Heartbeat loop works

Set a tiny `HEARTBEAT.md`:

```markdown
# HEARTBEAT.md
- If nothing needs attention, reply HEARTBEAT_OK
```

Trigger your heartbeat mechanism.

Expected:
- no extra chatter
- exact `HEARTBEAT_OK` when nothing is due

## 6. Cron model split is intentional

Check your config / cron definitions:
- heavy review jobs → `gpt-5.4` + `medium`
- routine checks → `spark` + `low`
- mechanical loops → `spark` + `disabled`

Expected:
- no accidental expensive model on high-frequency jobs
- no stale old-provider model strings in active config

## 7. Sub-agent verification loop exists

Spawn one sub-agent for a bounded task, then verify output manually:
- inspect files changed
- run tests
- check diff

Expected:
- no "trust the agent blindly" behavior

## Exit Criteria

You are ready to build on the playbook when:
- memory is writable and searchable
- tasks are visible in SQLite
- heartbeat works
- one hook can block unsafe actions
- cron models/thinking are intentional
- sub-agent output is verified, not trusted
