# Chapter 15: Context Management

LLM context windows are finite. Every token of conversation history, every bootstrap file, every tool output — it all competes for space. When the window fills up, OpenClaw compacts older content and details are lost. This chapter covers how to structure your agent's work so important state survives.

## The Problem

Here's what happens during a long session:

```
Session starts
├── Bootstrap files loaded (~8K tokens)
├── MEMORY.md loaded (~3K tokens)
├── Conversation begins
│   ├── User messages + agent responses accumulate
│   ├── Tool calls and their outputs accumulate
│   ├── Context usage: 30%... 50%... 70%...
│   ├── ⚠️ Context at 85% — compaction triggered
│   │   └── Older messages summarized to free space
│   ├── Conversation continues with summarized history
│   ├── ⚠️ Context at 85% again — another compaction
│   │   └── More detail lost
│   └── Eventually: only recent messages + summaries remain
└── Session ends or restarts
```

What gets lost during compaction:
- **Exact commands** that were run earlier in the session
- **Specific file contents** that were read and discussed
- **Nuanced decisions** with their full reasoning
- **Error details** from debugging sessions
- **Task context** that was only in conversation, not in files

What survives:
- **Bootstrap files** (reloaded from disk, not from conversation)
- **Summaries** of compacted conversations (high-level, details stripped)
- **Files on disk** (anything written to the filesystem)

The insight: **if it's only in the conversation, it's temporary. If it's in a file, it persists.**

## Pre-Compaction Memory Flush

Before context fills up, write important state to files. The agent should develop a habit of offloading context to disk throughout the session, not waiting until compaction happens.

### What to Write

```markdown
# memory/2026-04-03.md

## 14:30 — Dashboard Refactor
- Decision: moving from REST to WebSocket for real-time updates
- Reason: polling every 5s was causing 429 rate limits on the API
- Files changed: src/api/socket.ts (new), src/hooks/useData.ts (modified)
- TODO: still need to update the deployment config for WebSocket support
- Blocker: nginx needs proxy_pass upgrade for ws:// protocol
```

### When to Write

- **After making a decision** — capture the "what" and "why" immediately
- **After solving a problem** — the error, root cause, and fix. Future sessions will thank you.
- **Before long operations** — if you're about to run a 10-minute build, write down where you are first
- **When context is getting heavy** — if the session has been going for a while, proactively flush state
- **At natural breakpoints** — switching topics, finishing a task, pausing for human input

## Project Files as Compaction Insurance

Project files (`projects/project-name.md`) are loaded at session start via bootstrap, not from conversation history. This makes them compaction-proof.

```markdown
# Dashboard Refactor
**Status:** active
**Last updated:** 2026-04-03

## TODO
- [x] Set up WebSocket server
- [x] Migrate data hooks to WebSocket
- [ ] Update nginx config for ws:// proxy
- [ ] Update deployment scripts
- [ ] Load test with 50 concurrent connections

## Decisions
- 2026-04-03: REST → WebSocket for real-time updates (429 rate limits)
- 2026-04-02: Using socket.io over raw WebSocket (reconnection handling)
```

If the session compacts or restarts, the next session reads this file and knows exactly where things stand. The conversation history might be gone, but the project state is intact.

**Update project files as you go.** Don't wait until the end of the session — by then, you might have already lost context to compaction.

## Structuring Work for Resilience

### Keep State in Files, Not Conversation

| Fragile (conversation only) | Resilient (in files) |
|---|---|
| "I decided to use WebSocket" | `projects/dashboard.md` → Decisions section |
| "The bug was in line 42 of auth.ts" | `memory/2026-04-03.md` → ## Bug Fix section |
| "We still need to update nginx" | `projects/dashboard.md` → TODO checkbox |
| "The API key format is sk-proj-..." | Should never be anywhere, but especially not in conversation |

### Update TODOs in Real-Time

When you complete a task, check it off in the project file immediately:

```bash
# Don't: finish work, plan to update the file "later"
# Do: check off the TODO right after completing the task
```

"Later" often means "after compaction" which means "the agent doesn't remember what was completed."

### Write Decisions Immediately

When a decision is made during conversation, write it to the project file or daily note in the same turn. Not the next turn. Not after the current task. Now.

The decision's reasoning is the first thing compaction strips. The conclusion might survive as a summary, but "we chose X because of Y and Z" becomes "X was chosen" — and the reasoning was the valuable part.

## Bootstrap Files

Bootstrap files are loaded into every session as project context. They're specified in `openclaw.json`:

```json
{
  "agents": {
    "defaults": {
      "bootstrapFiles": [
        "AGENTS.md",
        "SOUL.md",
        "IDENTITY.md",
        "USER.md",
        "TOOLS.md"
      ],
      "bootstrapMaxChars": 20000,
      "bootstrapTotalMaxChars": 50000
    }
  }
}
```

### What These Limits Mean

- **`bootstrapMaxChars`** — maximum characters per individual file. If TOOLS.md is 25,000 chars, only the first 20,000 load (with a truncation warning).
- **`bootstrapTotalMaxChars`** — maximum total characters across all bootstrap files. If your five files total 60,000 chars, the last files get truncated.

### Why Limits Matter

Bootstrap files load every single session — main sessions, cron jobs, sub-agents, heartbeats. Every token of bootstrap is a token that can't be used for conversation or tool output.

A 50K bootstrap means:
- On a 200K context window: 25% consumed before the agent does anything
- Every cron job pays this tax, even for a "check disk space" one-liner
- Sub-agents pay this tax on top of their task description

### Sizing Guidelines

| File | Target Size | Why |
|------|------------|-----|
| AGENTS.md | < 4,000 chars | Most important file, but keep it focused |
| SOUL.md | < 2,000 chars | Personality doesn't need a novel |
| IDENTITY.md | < 1,000 chars | It's an ID card, not a biography |
| USER.md | < 2,000 chars | Key facts, not life story |
| TOOLS.md | < 5,000 chars | Infrastructure notes, not documentation |
| **Total** | **< 15,000 chars** | Leave room for actual work |

If a file is growing past its target, move volatile content to `memory/` or reference files that the agent reads on demand.

## Session Types and Their Context

Different session types have different context characteristics:

### Main Session
- **Bootstrap:** Full set (AGENTS.md, SOUL.md, etc.)
- **MEMORY.md:** Loaded (private sessions only)
- **History:** Full conversation history (subject to compaction)
- **Context pressure:** Highest — long conversations accumulate

This is where compaction matters most. Long troubleshooting sessions, multi-step builds, and extended conversations all risk context loss.

### Cron Sessions (Isolated)
- **Bootstrap:** Full set
- **MEMORY.md:** Not loaded
- **History:** None — fresh session with only the cron prompt
- **Context pressure:** Low — starts and ends quickly

Cron sessions are naturally resilient to compaction because they're short-lived. But they still pay the bootstrap tax, so keep bootstrap files lean.

### Heartbeat
- **Bootstrap:** Full set
- **MEMORY.md:** Loaded (if main session)
- **History:** Main session's history (it's a poll in the main session)
- **Context pressure:** Contributes to main session context

Heartbeats add to the main session's context. A heartbeat that runs 48 times a day and generates verbose output contributes to compaction. Keep heartbeat responses concise — `HEARTBEAT_OK` when nothing needs attention.

### Sub-Agent
- **Bootstrap:** Full set
- **MEMORY.md:** Not loaded (security isolation)
- **History:** None — only the task description
- **Context pressure:** Independent — doesn't affect parent session

Sub-agents are naturally isolated. They can't be compacted because they start fresh. But they also can't benefit from conversation context — everything they need must be in the task description or on disk.

Cross-reference: see [Chapter 13](13-sub-agents.md) for sub-agent patterns. See [Chapter 6](06-cron-patterns.md) for heartbeat vs cron decisions.

## Tips for Context Efficiency

### Keep AGENTS.md Under Control
AGENTS.md is the largest bootstrap file and loaded every session. Audit it regularly:
- Remove instructions for tools you no longer use
- Move detailed procedures to skill files (loaded on demand)
- Replace verbose explanations with concise rules
- Use cross-references instead of duplicating information

### Don't Bloat TOOLS.md
TOOLS.md grows organically as your agent discovers infrastructure. Periodically prune:
- Remove notes about decommissioned services
- Move project-specific details to project files
- Archive historical notes that aren't operationally relevant

### Use Memory Files for Volatile Data
Data that changes frequently shouldn't live in bootstrap files:
- Heartbeat check timestamps → `memory/heartbeat-state.json`
- Current task context → `memory/YYYY-MM-DD.md`
- Temporary debugging notes → daily memory file

### Structure Long Sessions
If you're doing complex work that'll take many turns:
1. Start with a project file (create one if it doesn't exist)
2. Write state to the project file after each major step
3. If you notice context getting heavy, proactively flush to memory
4. After compaction, re-read the project file to restore context

### Monitor Context Usage
Some LLM providers report context usage. Watch for:
- Sessions that consistently hit 80%+ context
- Bootstrap files that have grown since last check
- Cron jobs that generate unexpectedly verbose output

---

## Playbook Complete

You've reached the end of the OpenClaw Playbook. Here's the full implementation path:

1. **Foundations** (Ch 1) — Set up workspace, customize identity files
2. **Memory** (Ch 2) — Install memory extraction, configure daily notes
3. **Tasks** (Ch 3) — Build the task CLI, enforce Rule Zero
4. **Hooks** (Ch 4) — Build security hooks first, then automation
5. **Security** (Ch 5) — Implement defense in depth
6. **Crons** (Ch 6) — Set up heartbeats and essential cron jobs
7. **Scripts** (Ch 7) — Build your utility toolkit
8. **Dashboard** (Ch 8) — Create visibility into agent activity
9. **Config** (Ch 9) — Finalize and backup your configuration
10. **Clones** (Ch 10) — Scale to additional instances when ready
11. **Nodes** (Ch 11) — Connect companion devices
12. **A2A** (Ch 12) — Enable inter-agent collaboration
13. **Sub-Agents** (Ch 13) — Orchestrate parallel and delegated work
14. **Skills** (Ch 14) — Build specialized instruction sets
15. **Context** (Ch 15) — Manage context windows for resilience

Build incrementally. Start with chapters 1-5, get stable, then expand. The best agent infrastructure is the one that compounds over time — each layer you add makes everything else more effective.

Good luck building. 🦞

## What to Build

- [ ] Audit your bootstrap files — are they under the size guidelines?
- [ ] Set `bootstrapMaxChars` and `bootstrapTotalMaxChars` in your config
- [ ] Add "write decisions immediately" to your AGENTS.md behavioral rules
- [ ] Create a project file template (see `schemas/project-template.md`)
- [ ] Practice the pre-compaction flush: write state to files during long sessions
- [ ] Move volatile data out of bootstrap files into memory files
- [ ] Monitor context usage across session types
- [ ] Set up TOOLS.md pruning as a periodic maintenance task
- [ ] Review AGENTS.md for content that should move to skills

---

*Previous: [Chapter 14 — Skills System](14-skills.md) | Next: [Chapter 16 — Infrastructure & Networking](16-infrastructure.md)*
