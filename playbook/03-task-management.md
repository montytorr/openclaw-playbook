# Chapter 3: Task Management

Rule Zero: track before you work. This chapter documents the task management system that makes Rule Zero possible.

## Brownfield Adoption: Wrap Before You Replace

If you already have a task API or CLI, do not rebuild it on reflex.

Strong default:
- **wrap** the existing interface if a thin adapter can give you playbook-compatible `start`, `update`, `list`, `show`, and stable IDs
- **replace** only when the current interface is so inconsistent that the wrapper becomes fiction

A simple mapping template:

| Existing field | Playbook concept | Migration convention |
|---|---|---|
| `category` | category/project | keep as category unless it really identifies a long-lived project |
| `input` | input | use for request / reason / trigger |
| `output` | output | use for delivered result / accomplishment |
| `description` | input/output split | split request vs result during migration where possible |
| `status=todo/backlog` | `planned` | backlog semantics can remain in UI language |
| `status=doing/active` | `in-progress` | direct mapping |
| `status=done/complete` | `done` | direct mapping |

If your legacy system relies on extra states like `blocked` or `cancelled`, keep them in wrapper metadata instead of bloating the core playbook status model too early.

See [Chapter 0](00-brownfield-adoption.md) for the full adapter template and wrapper-vs-replace decision path.

## Philosophy: Why Rule Zero Exists

We tried everything else first:
- "Remember to track your work" — agent forgot within 3 messages
- "Track work at the end of each session" — sessions end unexpectedly, nothing captured
- "3-second rule: track within 3 seconds of completing work" — buried too deep in instructions, routinely ignored

What finally worked: making task tracking the literal first instruction. Before any work begins — before reading files, before running commands, before responding — track it. That's Rule Zero.

The dashboard Projects tab should reflect reality. If your agent did work and the dashboard is empty, the system has failed.

## The Task CLI

The task management system is a CLI tool backed by SQLite. No HTTP API, no external service — just a script that reads and writes a local database.

In the reference implementation, not-found operations are intentionally explicit: `show`, `update`, `set-input`, and `delete` exit with code `2` when the task ID does not exist.

### Interface

If you want a tiny starting point instead of building from zero, see `reference/scripts/task` in the repo. It is intentionally small, but it proves the loop is executable.

```bash
# Start work on something
task start "Title" "What's being requested" [category] [priority]

# Complete something (creates a new done task)
task done "Title" "What was requested" "What was accomplished" [category]

# Plan future work
task plan "Title" "What needs to happen" [category]

# Update an existing task
task update <id> <status> "Description of update"

# Set input on existing task (what was requested)
task set-input <id> "What was requested"

# List tasks
task list                  # Recent 10 tasks
task list done             # All completed tasks
task list in-progress      # Currently active tasks
task list planned          # Future work

# Delete a task
task delete <id>   # exits 2 if the ID does not exist

# Search tasks
task search "query"

# Show task details
task show <id>     # exits 2 if the ID does not exist

# Sprint view (grouped by category)
task sprint
```

### Behavioral Triggers

These patterns in conversation should trigger immediate task tracking:

| Trigger | Action |
|---------|--------|
| "fix", "fixed", "fixing" | `task done` with what was fixed |
| "entered position", "bought", "sold" | `task done` for each trade |
| "created", "built", "implemented" | `task done` with what was created |
| "updated", "changed", "modified" | `task done` if the change is significant |
| Human says "do X" | `task start` before doing X |
| Starting multi-step work | `task start` first |

### Input vs Output

Every task should have both:
- **Input** — what was requested or why the work is happening
- **Output** — what was accomplished or delivered

Tasks without input are useless for review. "Fixed bug" tells you nothing. "Fixed null reference in dashboard render loop causing blank Projects tab on page reload" tells you everything.

## Database Schema

```sql
CREATE TABLE tasks (
    id TEXT PRIMARY KEY,          -- Short hash (8 chars) or UUID
    title TEXT NOT NULL,
    input TEXT,                   -- What was requested
    output TEXT,                  -- What was accomplished
    status TEXT DEFAULT 'planned', -- in-progress, done, planned
    category TEXT DEFAULT 'other', -- Configurable categories
    priority TEXT DEFAULT 'medium', -- low, medium, high, urgent
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index for common queries
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_category ON tasks(category);
CREATE INDEX idx_tasks_created ON tasks(created_at);
```

### Status Transitions

```
planned → in-progress → done
                ↑
                └── (can also go directly from planned to done)
```

- **planned** — future work, not started
- **in-progress** — actively being worked on
- **done** — completed

There is no "cancelled" or "blocked" status by design. If something isn't happening, delete it or leave it planned. Simplicity matters more than comprehensive state machines.

### Categories

Categories are configurable per deployment. Example set:

- `main` — general work, conversations, misc tasks
- `dashboard` — dashboard features, fixes, deployments
- `trading` — trading operations, position entries/exits
- `infrastructure` — server, Docker, networking, cron
- `openclaw` — OpenClaw configuration, hooks, skills
- `other` — catch-all

Pick categories that match your domains of work. 4-8 categories is the sweet spot — enough to filter, few enough to remember.

## Dashboard Integration

The task database feeds the dashboard Projects tab:

```
SQLite (tasks table) → Dashboard reads directly → Web UI
```

The dashboard shows:
- Active tasks (in-progress) at the top
- Recent completed tasks
- Filtering by category and status
- Task details on click (input, output, timestamps)

This is why Rule Zero matters: the dashboard is your human's window into what the agent is doing. Empty dashboard = zero visibility.

Cross-reference: see Chapter 8 for dashboard setup.

## Anti-Pollution: Cron Task Detection

Problem: cron jobs and automated processes can create tasks, leading to stale "in-progress" entries that never get completed (because the session that created them ended).

Solution: a periodic cleanup that:
1. Finds in-progress tasks older than a threshold (e.g., 24 hours)
2. Checks if they were created by a cron/automated session
3. Either marks them done with a note or deletes them

This prevents the dashboard from filling up with zombie tasks.

## Task Reconciliation

When the agent calls `task done`, the system should first check if there's a matching in-progress task:

1. Search for in-progress tasks with similar titles or categories
2. If found: update that task to done (preserving the full history)
3. If not found: create a new done task (the agent forgot to `task start` — it happens)

This graceful degradation means work still gets tracked even when Rule Zero is violated.

## Integration Points

The task system connects to several other systems:

| System | Integration |
|--------|------------|
| Dashboard | Direct SQLite read for Projects tab |
| Hooks | `auto-task-capture` hook can create tasks from detected activity |
| Cron | Anti-pollution cron cleans stale tasks |
| Sub-agents | Parent creates task before spawning, sub-agent updates on completion |
| Memory | Task completions appear in daily notes |

## What to Build

- [ ] Build or adapt the `task` CLI script (see `reference/scripts/task` for a minimal starting point)
- [ ] Create the SQLite database with the tasks schema
- [ ] Add Rule Zero to your AGENTS.md (see template)
- [ ] Build anti-pollution cron job for stale task cleanup
- [ ] Implement task reconciliation in `task done`
- [ ] Connect your dashboard to read from the tasks database
- [ ] Define your category set and configure it
- [ ] Test the full flow: `task start` → do work → `task update done`

---

*Previous: [Chapter 2 — Memory System](02-memory-system.md) | Next: [Chapter 4 — Hooks](04-hooks.md)*
