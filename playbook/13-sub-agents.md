# Chapter 13: Sub-Agent Orchestration

Your agent doesn't have to do everything itself. For complex, risky, or parallelizable work, it can spawn isolated sub-agents — independent sessions that execute a specific task and report back. This chapter covers when, how, and why.

## What Sub-Agents Are

A sub-agent is an isolated session spawned via `sessions_spawn`. It gets:
- Its own context window (fresh, no conversation history from the parent)
- A task description (what to do)
- Access to the workspace filesystem
- Inherited security constraints via hooks

What it does NOT get:
- The parent's conversation history
- MEMORY.md access (security isolation)
- Ability to modify protected files (SOUL.md, AGENTS.md, etc.)
- Knowledge of what the parent discussed before spawning it

Think of it as delegating to a competent contractor: you give them a clear brief, they do the work, you verify the output.

## When to Use Sub-Agents

**Use them for:**
- **Coding tasks** — building features, refactoring, fixing bugs across multiple files
- **Parallel work** — 3-4 independent tasks on different files or projects simultaneously
- **Heavy processing** — large file analysis, codebase exploration, complex research
- **Risky operations** — if it goes wrong, the sub-agent's session is disposable
- **Isolation** — work that shouldn't pollute the main session's context

**Do NOT use them for:**
- **Simple one-liner fixes** — just edit the file directly. Spawning a sub-agent for `s/foo/bar/` is absurd.
- **Quick file reads** — use the `read` tool. Don't spawn a session to read a file.
- **Anything needing main session context** — sub-agents start fresh. If the task requires knowing what you just discussed, do it in the main session.
- **Trivial tasks** — each sub-agent has cost (context load, API call). Don't waste it on 10-second work.

The cost heuristic: if the task takes less than 30 seconds to do manually, don't spawn a sub-agent for it.

## The Parent-Child Pattern

Every sub-agent interaction follows this flow:

```
Parent Session
    │
    ├── 1. Create a task (track the work BEFORE spawning)
    │       task start "Build authentication module" "User requested login flow" coding
    │
    ├── 2. Spawn sub-agent with clear task description
    │       sessions_spawn(task="...", mode="run", cwd="/path/to/project")
    │
    ├── 3. Sub-agent executes independently
    │       (reads files, writes code, runs tests)
    │
    ├── 4. Sub-agent completes and reports back
    │       (auto-announced to parent)
    │
    └── 5. Parent verifies output
            git diff, file reads, build checks
```

### The "Create Task Before Spawning" Rule

**Always track the work BEFORE spawning the sub-agent.** This exists because:

1. Sub-agents sometimes fail silently (timeout, error, incomplete work)
2. Without a task, there's no dashboard visibility into what was delegated
3. If the parent session compacts before the sub-agent finishes, the task record is the only evidence of what was requested

```bash
# CORRECT: track first, spawn second
task start "Refactor auth module" "Extract JWT logic into separate service" coding
# then spawn sub-agent

# WRONG: spawn first, track maybe-later
sessions_spawn(task="Refactor auth module...")
# forgot to track, now it's invisible
```

## Parallel Execution

Sub-agents shine when you have independent work that can run simultaneously.

```
Parent: "Build the user dashboard"
    │
    ├── Sub-Agent A: "Build the frontend components"  (in /src/components/)
    ├── Sub-Agent B: "Build the API endpoints"         (in /src/api/)
    ├── Sub-Agent C: "Write the database migrations"   (in /src/db/)
    └── Sub-Agent D: "Set up test infrastructure"      (in /tests/)
```

**Rules for parallel execution:**
- Each sub-agent works on **different files/directories** (no conflicts)
- 3-4 parallel agents is the practical maximum (more gets hard to track)
- Create a task for EACH sub-agent before spawning
- Wait for all completions before integrating
- Verify each agent's output independently

**What can go wrong:**
- Two sub-agents editing the same file → merge conflicts
- One sub-agent's work depends on another's output → race condition
- Sub-agent makes incorrect assumptions about project structure → broken code

Prevent these by giving each agent a clearly scoped, independent task.

## Timeout Guide

Sub-agents need timeouts. Without them, a stuck agent burns tokens indefinitely.

| Task Scope | Timeout | Examples |
|-----------|---------|---------|
| Small edits | 300s (5 min) | Fix a typo, update a config, add a function |
| Single feature | 600s (10 min) | Build one component, implement one endpoint |
| Sprint work | 1200s (20 min) | Multiple related changes across a project |
| Massive refactor | 1800s (30 min) | Restructuring a codebase, large migration |

These are starting points. Adjust based on your experience. If sub-agents consistently time out, either the task is too large (break it up) or the timeout is too short.

## Verification

**Sub-agents can produce incorrect output.** This is not a possibility — it's a near-certainty for any non-trivial task. They will:
- Claim they completed something they didn't
- Write code that doesn't compile
- Make changes in the wrong files
- Miss edge cases they were explicitly told about
- Report success when they actually errored out

**Always verify:**

```bash
# Check what actually changed
git diff

# Read the modified files
read <file>

# Run the build/tests
npm test
# or
python -m pytest

# Check for syntax errors
node --check <file>.js
python -c "import ast; ast.parse(open('<file>.py').read())"
```

The verification step is not optional. "The sub-agent said it worked" is not verification.

## Mode Options

### `mode="run"` — One-Shot

The sub-agent receives the task, executes it, and completes. Its final message is automatically delivered back to the parent. This is the default for most work.

```
sessions_spawn(
  task="Fix the login redirect bug in auth.ts",
  mode="run",
  cwd="/root/projects/my-app",
  runTimeoutSeconds=600
)
```

Use for: defined tasks with clear completion criteria.

### `mode="session"` — Persistent

The sub-agent stays alive after initial execution. The parent can send additional messages to it via `sessions_send`. Useful for iterative work where you might need to course-correct.

```
sessions_spawn(
  task="Set up the test infrastructure",
  mode="session",
  cwd="/root/projects/my-app"
)

# Later, after reviewing initial output:
sessions_send(sessionKey="<key>", message="Also add integration test helpers")
```

Use for: exploratory work, multi-step tasks that need human-in-the-loop feedback, or tasks where you might need to adjust direction.

## Runtime Options

### `runtime="subagent"` — Built-In

Uses OpenClaw's built-in sub-agent system. The sub-agent is another instance of your configured model, running in an isolated session with workspace access.

```
sessions_spawn(
  task="...",
  runtime="subagent",
  mode="run"
)
```

### `runtime="acp"` — External Coding Agents

Connects to external coding agent runtimes like Codex, Claude Code, or other ACP-compatible tools. These run as separate processes with their own capabilities.

```
sessions_spawn(
  task="...",
  runtime="acp",
  agentId="codex",
  thread=true
)
```

Use ACP when:
- The external agent has specialized capabilities (e.g., Codex's code generation)
- You want the work to happen in a thread-bound session (e.g., Discord thread)
- The task benefits from a different model or tool chain

## Security

Sub-agents inherit security constraints through hooks, specifically:

- **`agent-firewall`** injects security rules at session start — sub-agents get the same rules
- **`the-wall`** intercepts tool calls — sub-agents are gated by the same credential scanner and tier system
- **`delegation-audit`** logs every sub-agent spawn with context
- **`delegation-policy`** enforces spawn limits and allowed operations

What sub-agents CANNOT do:
- Access MEMORY.md (memory segmentation)
- Modify protected files (SOUL.md, AGENTS.md, IDENTITY.md, SECURITY.md)
- Read `.env` or credential files
- Override security hooks
- Spawn further sub-agents beyond the configured depth limit

If a sub-agent is compromised (e.g., by prompt injection from a file it reads), the damage is contained to its isolated session. The main session is unaffected.

Cross-reference: see [Chapter 4](04-hooks.md) for delegation-audit and delegation-policy hook patterns. See [Chapter 5](05-security.md) for the full security model.

## Cost Considerations

Each sub-agent is a separate API session. That means:
- **Context load cost** — bootstrap files (AGENTS.md, SOUL.md, etc.) are loaded fresh
- **Per-session overhead** — the task description, security injections, and initial context add up
- **Model cost** — if your main agent uses an expensive model, sub-agents do too (unless you override)

**Cost optimization:**
- Don't spawn sub-agents for trivial tasks
- Use cheaper models for routine sub-agent work (via model override)
- Batch related small tasks into one sub-agent instead of spawning five
- Set appropriate timeouts to prevent runaway sessions
- Monitor sub-agent costs via the `llm-observer` hook
- Default sub-agent thinking to `off`, then escalate only when the task is genuinely synthesis-heavy or keeps failing for non-mechanical reasons

A good rule of thumb: if the sub-agent's context load (bootstrap + task) costs more than doing the work yourself, just do it yourself.

## What to Build

- [ ] Set up `delegation-audit` hook to log all sub-agent spawns
- [ ] Set up `delegation-policy` hook to enforce spawn limits
- [ ] Configure sub-agent depth limits in your security rules
- [ ] Add task tracking discipline: always `task start` before `sessions_spawn`
- [ ] Build a verification checklist for sub-agent output (git diff, tests, file checks)
- [ ] Set up cost monitoring for sub-agent sessions
- [ ] Test parallel spawning with 2-3 independent tasks
- [ ] Document timeout guidelines in your TOOLS.md based on your experience
- [ ] Configure model overrides for cost-sensitive sub-agent tasks

---

*Previous: [Chapter 12 — A2A Communication](12-a2a-comms.md) | Next: [Chapter 14 — Skills System](14-skills.md)*
