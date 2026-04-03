# Chapter 1: Foundations

The workspace structure and core identity files that make an autonomous agent work.

## Why Structure Matters

An autonomous agent without structure is just a chatbot with extra steps. The difference between "AI assistant" and "autonomous operator" is infrastructure — files that persist across sessions, scripts that enforce behavior, and conventions that prevent entropy.

Three truths about LLM-based agents:

1. **Every session starts fresh.** The agent has no inherent memory between conversations. Files ARE the agent's continuity.
2. **Instructions drift without anchoring.** Without explicit files defining behavior, the agent gradually reverts to generic assistant mode.
3. **Complexity requires organization.** An agent managing infrastructure, trades, projects, and communications needs a workspace as organized as a developer's codebase.

## Workspace Layout

```
~/clawd/                     (or your chosen workspace path)
├── AGENTS.md               # Main instruction set — the operating manual
├── SOUL.md                 # Personality, voice, behavioral guardrails
├── IDENTITY.md             # Who the agent is
├── USER.md                 # Who the human is
├── HEARTBEAT.md            # Heartbeat poll configuration
├── TOOLS.md                # Local infrastructure notes
├── SECURITY.md             # Security rules (read-only to agent)
├── MEMORY.md               # Auto-generated observation index (read-only)
├── memory/                 # Daily notes and state files
├── projects/               # Active project tracking
│   └── archive/            # Completed projects
├── scripts/                # Utility scripts and CLIs
├── hooks/                  # OpenClaw hook implementations
├── config/                 # Configuration files
├── logs/                   # Audit logs and activity logs
├── canvas/                 # Canvas states and exports
├── security/               # Security documentation and baselines
├── data/                   # Runtime data and state
├── feedback/               # Decision feedback logs
└── .proposed/              # Staging area for protected file edits
```

Every directory has a purpose. Empty directories are fine — they'll fill as your agent operates.

## Core Identity Files

### AGENTS.md — The Operating Manual

This is the most important file in your workspace. OpenClaw injects it into every session as project context. It defines how your agent thinks, works, and behaves.

#### Rule Zero — Track Before You Work

Every action gets tracked. Before touching anything, the agent runs `task start`. After completing, `task update done`. No exceptions.

This exists because agents reliably forget to track work unless it's the absolute first instruction. We tried softer approaches:
- "Remember to track your work" — agent forgot within 3 messages
- "3-second rule: track within 3 seconds" — buried too deep in instructions, routinely ignored
- "Track work at the end of each session" — sessions end unexpectedly, nothing captured

Making it Rule Zero — literally the first thing in the file — is what finally worked.

**Why it matters:** Without tracking, your agent becomes a black box. You have no visibility into what happened, when, or why. The dashboard stays empty. Debugging becomes archaeology.

#### Session Startup Ritual

Every session, the agent reads its identity files, checks recent memory, and loads active projects. This isn't optional — it's how the agent maintains continuity across sessions.

The sequence:
1. Read `SOUL.md` (who am I)
2. Read `USER.md` (who am I helping)
3. Read `memory/YYYY-MM-DD.md` (today + yesterday) for recent context
4. In main sessions: read `MEMORY.md` (long-term context)
5. Check `projects/` for active project files

Without this ritual, each conversation starts from zero context. The agent doesn't know what it was working on, what decisions were made, or what's coming up.

#### Memory Section

Instructions for how to use daily notes, when to write to memory files, and the distinction between raw daily logs and the auto-generated MEMORY.md index.

Cross-reference: see [Chapter 2](02-memory-system.md) for the full memory system.

#### Project Tracking

For multi-step or multi-day work, project files in `projects/` serve as the source of truth. They survive context resets, compaction, and session boundaries.

Each project file follows a template:
- **Goal** — what are we trying to accomplish
- **Plan** — how we'll get there
- **TODO** — specific tasks with checkboxes
- **Decisions** — what was decided and why
- **Notes** — anything else worth remembering

When a project is done, set `Status: done` and optionally archive to `projects/archive/`.

#### Task Tracking

The CLI interface and behavioral rules for real-time task tracking.

Cross-reference: see [Chapter 3](03-task-management.md) for the full task management system.

#### Feedback & Self-Critique

Two learning systems that compound over time:

- **Feedback tracking** — logs human decisions (approved/rejected/modified) with reasons. Over time, patterns emerge: "my trading recommendations get rejected when they're momentum-based during low-volume periods."
- **Self-critique** — 3-pass review system for high-stakes outputs (criteria check → red flag scan → refinement). Run important drafts through this before executing.

#### Safety Rules

Simple, non-negotiable:
- Never exfiltrate private data
- `trash` over `rm` (recoverable beats gone forever)
- When in doubt, ask

#### External vs Internal Actions

A critical boundary:
- **Internal** (read, analyze, organize, search): free to do anytime
- **External** (email, tweet, public post, GitHub issue): ask first

This boundary is enforced by hooks (see [Chapter 4](04-hooks.md)).

#### Group Chat Behavior

When your agent participates in group chats:
- Respond when directly mentioned, when you can add genuine value, or when something witty fits naturally
- Stay silent when it's casual banter, someone already answered, or your response would be filler
- React with emoji when acknowledgment beats a full reply
- Participate, don't dominate — quality over quantity

The human rule: humans don't respond to every message in a group chat. Neither should your agent.

#### Heartbeat Section

Instructions for what the agent should do during heartbeat polls: check email, calendar, system health, mentions. Track check timestamps in `memory/heartbeat-state.json`. Respect quiet hours. Be proactive but not annoying.

Cross-reference: see [Chapter 6](06-cron-patterns.md) for heartbeat vs cron patterns.

#### Write It Down — No Mental Notes

A critical behavioral rule: if you want to remember something, WRITE IT TO A FILE. "Mental notes" don't survive session restarts. Text > brain.

When someone says "remember this" → update the daily memory file immediately. Not "later." Not "at the end of the conversation." NOW.

The number of times an agent says "I'll remember that" and then doesn't because the session ended is: all of them.

#### Mandatory Memory Search

Before answering questions about past events, people, decisions, or preferences: STOP and search memory first.

Trigger phrases that require a memory search:
- "remember when", "did we", "wasn't there", "what about"
- "who is [name]", "tell me about [person]"
- "when did", "how long ago", "last time"
- "what was", "didn't we", "I thought we"

The rule: if the agent is about to answer from "memory" without actually checking files — STOP. Run a search first. The agent's confidence about past events is often wrong. Files are truth.

---

### SOUL.md — Personality & Voice

Why this file exists: without it, your agent defaults to "helpful assistant" mode — the bland, hedging, corporate bot syndrome that makes every AI interaction feel the same.

SOUL.md defines:

- **Core truths** — strong opinions, brevity, resourcefulness, honesty. These are the non-negotiable behavioral principles. Example: "Never open with 'Great question!' — just answer."
- **Behavioral lessons** — hard-won patterns like "execute don't instruct" (do the work, don't hand back terminal commands), "verify don't trust" (sub-agents lie, check their output), "proactive over reactive" (fix things before being asked).
- **Boundaries** — what the agent will and won't do without permission.
- **Vibe** — the personality. This is where you define character. Dry wit? Formal? Casual? Sardonic? Pick a voice and commit to it. A well-defined personality is a quality filter.
- **Continuity** — reminder that files are memory; read them, update them.

The key insight: personality isn't cosmetic. An agent with defined character makes better decisions because it has a consistent framework for judgment. "Would this response match my voice?" is a surprisingly effective quality check.

---

### IDENTITY.md — The ID Card

Minimal but important:
- **Name** and nickname
- **Creature/avatar** — a visual metaphor that adds character
- **Emoji** — quick visual identifier
- **Roles** — what the agent does (operator, builder, trader, etc.)
- **Personality summary** — 2-3 sentences for quick reference
- **Origin** — optional but adds character

This file is injected into context and helps the agent maintain consistent self-reference, especially in group chats where multiple bots might be present.

---

### USER.md — About the Human

Everything your agent needs to know about you:

- **Basics** — name, location, timezone, email
- **Work & projects** — what you do, what you're building
- **Communication style** — brevity vs detail, formal vs casual, how you prefer to be updated
- **Decision patterns** — when you approve fast, when you push back, what triggers rejection
- **Schedule** — quiet hours, busy periods, travel
- **People** — names that come up in conversation, with enough context for the agent to follow along

This file is security-sensitive — it contains personal information. It loads in all sessions, but MEMORY.md (which may contain more sensitive context) only loads in private sessions.

---

### HEARTBEAT.md — Lightweight Config

A small file the agent reads during heartbeat polls. Contains:
- **Policy** — what to check, how often, when to stay quiet
- **Checklist items** — email, calendar, system health, task cleanup
- **Command handlers** — respond to /status with a system report, etc.

Keep this file small — it's read frequently and should add minimal token overhead. Think 20-30 lines, not 200.

---

### TOOLS.md — Local Notes

Not about how tools work (that's in skill files) — about YOUR specifics:
- Browser profiles and which to use when
- SSH details and server names
- Project-specific notes (repo paths, API endpoints, database locations)
- Infrastructure quirks worth remembering
- Service account notes (non-secret details)

This file grows organically as your agent discovers things about your setup. It's the agent's personal notebook for operational knowledge.

---

## The Protection Hierarchy

Not all files are equal. Some are too important for the agent to modify without human approval:

| File | Agent Can Read | Agent Can Write | Why |
|------|:---:|:---:|-----|
| SOUL.md | ✅ | ❌ (proposal only) | Personality shouldn't drift without human approval |
| AGENTS.md | ✅ | ❌ (proposal only) | Core instructions are too important to auto-edit |
| IDENTITY.md | ✅ | ❌ (proposal only) | Identity changes need human sign-off |
| SECURITY.md | ✅ | ❌ (proposal only) | Security rules must be human-controlled |
| USER.md | ✅ | ✅ | Agent learns about you over time |
| TOOLS.md | ✅ | ✅ | Agent discovers and documents infrastructure |
| HEARTBEAT.md | ✅ | ✅ | Agent manages its own heartbeat config |
| MEMORY.md | ✅ (private only) | ❌ (auto-generated) | Generated by extraction tool, not manually edited |

Protected files use a proposal flow: the agent stages an edit, shows you the diff, and waits for approval. This prevents personality drift, instruction corruption, and security rule weakening.

Cross-reference: see [Chapter 5](05-security.md) for the full security model including the proposal flow.

---

## What to Build

- [ ] Create your workspace directory structure (run `setup.sh`)
- [ ] Write your IDENTITY.md — give your agent a name and character
- [ ] Write your SOUL.md — define personality and behavioral guardrails
- [ ] Write your USER.md — tell your agent about yourself
- [ ] Customize AGENTS.md — adapt the template to your workflow
- [ ] Set up SECURITY.md — define what's protected and how
- [ ] Create your first `memory/YYYY-MM-DD.md` daily note manually
- [ ] Commit everything to git — this is your baseline

---

*Next: [Chapter 2 — Memory System](02-memory-system.md)*
