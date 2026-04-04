# Task CLI — Full Interface Specification

This document specifies the complete interface for the task management CLI. Build your own implementation that matches this interface to be compatible with the playbook's patterns.

## Commands

### `task start`

Start tracking a new piece of work.

```bash
task start <title> [input] [category] [priority]
```

| Argument | Required | Description |
|----------|----------|-------------|
| `title` | ✅ | Short description of the work |
| `input` | ❌ | What was requested / why this work is happening |
| `category` | ❌ | Category (default: `other`) |
| `priority` | ❌ | Priority level (default: `medium`) |

**Behavior:**
- Creates a new task with status `in-progress`
- Generates a unique short ID (8-character IDs are fine)
- Must be conflict-safe: repeated identical `start` calls should either return the existing in-progress task or generate a new non-colliding ID without crashing
- Sets `created_at` and `updated_at` to current timestamp
- Prints the task ID for reference

**Example:**
```bash
$ task start "Fix dashboard bug" "Tab navigation breaks on reload" dashboard high
Created task abc12345: Fix dashboard bug [in-progress] (dashboard/high)
```

### `task done`

Record completed work. Creates a new task with status `done`.

```bash
task done <title> [input] [output] [category]
```

| Argument | Required | Description |
|----------|----------|-------------|
| `title` | ✅ | Short description of what was done |
| `input` | ❌ | What was requested |
| `output` | ❌ | What was accomplished |
| `category` | ❌ | Category (default: `other`) |

**Behavior:**
1. First, searches for an existing `in-progress` task with a similar title
2. If found: updates that task to `done`, sets the output
3. If not found: creates a new task with status `done`
4. Sets `updated_at` to current timestamp

**Example:**
```bash
$ task done "Fixed null error" "Dashboard showing errors" "Added null check to renderErrors()" dashboard
Completed task abc12345: Fixed null error [done]
```

### `task plan`

Plan future work.

```bash
task plan <title> [input] [category]
```

| Argument | Required | Description |
|----------|----------|-------------|
| `title` | ✅ | Short description of planned work |
| `input` | ❌ | What needs to happen / requirements |
| `category` | ❌ | Category (default: `other`) |

**Behavior:**
- Creates a new task with status `planned`
- Sets priority to `medium` by default

### `task update`

Update an existing task.

```bash
task update <id> <status> [description]
```

| Argument | Required | Description |
|----------|----------|-------------|
| `id` | ✅ | Task ID |
| `status` | ✅ | New status: `in-progress`, `done`, or `planned` |
| `description` | ❌ | Update description (stored in output if moving to done) |

**Behavior:**
- Finds task by ID
- Updates status and `updated_at`
- If status is `done` and description provided, sets output

### `task set-input`

Set or update the input field on an existing task.

```bash
task set-input <id> <input>
```

**Behavior:**
- Finds task by ID
- Updates the input field
- Updates `updated_at`

### `task list`

List tasks with optional status filter.

```bash
task list [status] [--limit N]
```

| Argument | Required | Description |
|----------|----------|-------------|
| `status` | ❌ | Filter by status: `in-progress`, `done`, `planned` |
| `--limit` | ❌ | Number of results (default: 10) |

**Default behavior (no status):** Shows the 10 most recently updated tasks.

**Output format:**
```
ID        Status       Category    Title                          Updated
abc12345  in-progress  dashboard   Fix dashboard bug              2m ago
def67890  done         main        Updated TOOLS.md               1h ago
ghi11111  planned      infra       Set up monitoring              2d ago
```

### `task delete`

Delete a task.

```bash
task delete <id>
```

**Behavior:**
- Permanently removes the task from the database
- Prints confirmation

### `task search`

Full-text search across task titles, inputs, and outputs.

```bash
task search <query>
```

**Behavior:**
- Searches title, input, and output fields
- Returns matching tasks ordered by relevance/recency
- Case-insensitive

### `task show`

Show full details of a specific task.

```bash
task show <id>
```

**Output:**
```
Task: abc12345
Title: Fix dashboard bug
Status: in-progress
Category: dashboard
Priority: high
Input: Tab navigation breaks on page reload
Output: (none)
Created: 2026-04-03 10:15:00
Updated: 2026-04-03 10:15:00
```

### `task sprint`

Sprint view — tasks grouped by category.

```bash
task sprint [--status in-progress]
```

**Output:**
```
=== dashboard (3 tasks) ===
  [in-progress] abc12345  Fix dashboard bug
  [planned]     def67890  Add cost tracking tab
  [planned]     ghi11111  Mobile responsive layout

=== infrastructure (1 task) ===
  [in-progress] jkl22222  Set up Traefik SSL

=== main (2 tasks) ===
  [done]        mno33333  Updated documentation
  [in-progress] pqr44444  Configure memory system
```

## SQLite Schema

```sql
CREATE TABLE IF NOT EXISTS tasks (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    input TEXT,
    output TEXT,
    status TEXT NOT NULL DEFAULT 'planned'
        CHECK (status IN ('in-progress', 'done', 'planned')),
    category TEXT NOT NULL DEFAULT 'other',
    priority TEXT NOT NULL DEFAULT 'medium'
        CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_category ON tasks(category);
CREATE INDEX IF NOT EXISTS idx_tasks_updated ON tasks(updated_at DESC);
```

## ID Generation

Use a short unique ID (8 chars is practical). Two sane patterns:

1. **Random short ID** (UUID-derived)
2. **Deterministic-with-conflict-handling**

The important rule is not the generator — it's that the CLI must **not crash on duplicate starts or collisions**.

## Status Transitions

```
planned ──→ in-progress ──→ done
   │                          ▲
   └──────────────────────────┘
        (direct to done)
```

Valid transitions:
- `planned` → `in-progress`
- `planned` → `done`
- `in-progress` → `done`
- `in-progress` → `planned` (rare, work paused)
- `done` → `in-progress` (reopened)

## Categories

Categories are strings — no fixed enum. Configure your own set:

```bash
# Suggested starter set
main            # General work, conversations
dashboard       # Dashboard features and fixes
infrastructure  # Server, Docker, networking
trading         # Trading operations (if applicable)
openclaw        # OpenClaw configuration
other           # Catch-all
```

The CLI should accept any string as a category. Validation is optional.

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error (invalid arguments, database error) |
| 2 | Task not found |

## Integration Points

| System | How It Connects |
|--------|----------------|
| Dashboard | Reads the SQLite database directly for the Projects tab |
| AGENTS.md | Rule Zero references the `task` CLI interface |
| Hooks | `auto-task-capture` creates tasks via this CLI |
| Cron | Anti-pollution cron calls `task list in-progress` to find stale tasks |
| Sub-agents | Parent agents call `task start` before spawning |
| Memory | Task completions should be noted in daily memory files |

## Database Location

Recommended: `<workspace>/data/agent.db` (or `<workspace>/clawd.db`)

The same SQLite file can hold multiple tables (tasks, trades, observations) — or use separate databases per domain. Single file is simpler; multiple files provide isolation.

Ensure the database path is in `.gitignore` — databases shouldn't be committed to git.
