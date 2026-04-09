# Chapter 2: Memory System

Your agent wakes up fresh every session. Without a memory system, it's perpetually amnesiac — helpful in the moment, useless over time. This chapter covers the infrastructure that gives your agent continuity.

## Brownfield Migration: Ingest Signal Before Noise

If you already have months of notes, exports, and logs, do **not** ingest everything at once.

Use a simple tiering model:

- **Tier A** — ingest first: project decisions, postmortems, durable operator preferences, recurring infra fixes, environment facts
- **Tier B** — ingest second: sprint summaries, task completions, issue/PR summaries, meeting notes with actual decisions
- **Tier C** — ingest last or skip: greetings, bootstrap chatter, empty acknowledgements, repetitive heartbeat noise, generic setup logs

The mistake is obvious in hindsight: indexing low-signal bootstrap noise first pollutes retrieval quality and makes the memory system feel dumb.

Practical brownfield rule:
- start with Tier A
- validate search quality
- add selected Tier B
- only ingest Tier C if you have a specific reason

If you need the full migration checklist and archive-first cleanup stance, see [Chapter 0](00-brownfield-adoption.md).

## The Problem

LLM sessions are stateless. Context windows are finite. When a session ends or the context fills up, everything the agent learned, decided, or discovered vanishes. During long sessions, OpenClaw automatically compacts older messages — summarizing them to free context space. Details are lost in the process. The memory system exists to make sure nothing important is permanently gone.

Cross-reference: see [Chapter 15](15-context-management.md) for the full context management model — what happens during compaction, how to structure work for resilience, and bootstrap file sizing.

The memory system solves the continuity problem with four layers:

1. **Daily notes** — raw, timestamped logs written throughout each day
2. **Observation database (SQLite)** — structured extracted memories with metadata, search, and ranking
3. **MEMORY.md** — an auto-generated semantic index of the most relevant observations
4. **Project files** — structured tracking for multi-day work

Together, these create a system where no important context is permanently lost, even across hundreds of sessions.

## The Bigger Framing: This Is Your LLM Wiki

Don't undersell this as "some notes plus a database." The durable memory stack is the foundation of an **LLM wiki**.

That framing matters because it changes how people build it:

- **Memory** is the purpose — preserving continuity, decisions, and context
- **Knowledge graph** is the structure — the linked model beneath the surface
- **LLM wiki** is the interface — the way humans and agents browse, search, and brief against that memory

In practice, the memory system should answer questions like:
- what do we already know about this project?
- what did we decide last time?
- which tasks, docs, and people connect to this issue?
- what context should a new sub-agent receive before it starts work?

Without that layer, your agent has logs. With it, your agent has usable memory.

## Why It Matters

Most teams discover the same failure mode the hard way:

- the agent seems brilliant in-session
- then a context reset happens
- or the session ends
- or the work resumes three days later
- and now everyone is re-explaining the same thing again

A real memory system fixes that.

Operationally, it gives you:

- **continuity across sessions**
- **fewer repeated explanations**
- **better handoffs to sub-agents and future sessions**
- **retrieval grounded in prior evidence rather than vibe**
- **compounding institutional memory instead of chat debris**
- **a knowledge surface humans can inspect and trust**

The blunt version: without memory, your AI is clever but amnesiac. With memory, it becomes cumulative.

## The Core Achievement: Hybrid Memory

This is one of the strongest patterns in the whole playbook: **memory is not one thing**.

The system works because it splits memory into two complementary layers:

- **Narrative memory** in markdown files (`memory/YYYY-MM-DD.md`, `MEMORY.md`, `projects/*.md`)
- **Structured memory** in SQLite (`data/memory.db` or equivalent)

Most agent setups only do one of these:
- **Only markdown** → human-readable, but weak search, ranking, and retrieval
- **Only database** → structured, but opaque and hard for humans to inspect or repair

The hybrid model gets both:
- humans can read and edit the narrative layer
- the agent can search and rank the structured layer
- `MEMORY.md` becomes the bridge between them

That matters. It turns memory from a vague aspiration into actual infrastructure.

## Knowledge Graph: Keep It Practical

If you expose the memory system in a dashboard knowledge page, you are implicitly building a knowledge graph whether you call it that or not.

The practical model is simple.

### Useful entity types

- memories
- notes
- documents
- tasks
- projects
- contracts
- people
- events
- external research
- decisions

### Useful relationships

- related to
- mentioned in
- derived from
- blocks
- owned by
- decided by
- last updated by
- source of truth for

This is enough to build a very capable LLM wiki.

Do **not** disappear into ontology theater. You don't need 70 node types before the thing is useful. Start with the objects your agent already touches every day and add structure only when retrieval quality benefits.

## Daily Notes

### Format

Daily notes live in `memory/YYYY-MM-DD.md`. One file per day, created automatically when the agent first writes to it.

```markdown
# 2026-04-03

## 09:15 — Session Start
- Read yesterday's notes, caught up on project status
- Dashboard deployment completed overnight

## 10:30 — Trading
- Entered AAPL position at $182, thesis: earnings momentum
- Set stop at $178

## 14:00 — Infrastructure
- Fixed Docker networking issue on dashboard container
- Root cause: bridge network DNS resolution after restart
- Solution: added explicit network aliases in docker-compose

## 16:45 — Memory Maintenance
- Reviewed last 3 days of notes
- Key pattern: dashboard issues cluster after Docker restarts
- Added restart hook to auto-verify container health
```

### What to Capture

- **Decisions** — what was decided and why (the "why" is the valuable part)
- **Discoveries** — things learned about systems, people, or processes
- **Changes** — what was modified, deployed, or configured
- **Context** — anything that would help a future session understand what happened
- **Errors** — what went wrong and how it was fixed (your agent's most valuable learning material)

### What to Skip

- Routine read operations (no need to log "read SOUL.md")
- Trivial conversations that don't contain decisions or context
- Secrets, credentials, or sensitive data (use secure storage for those)
- Low-signal noise that harms retrieval quality more than it helps

### Promotion Rule: Raw Notes vs Durable Memory

Not everything written down deserves promotion into durable memory.

A healthy system has at least three layers:

1. **raw capture** — daily notes, session activity, logs
2. **durable observations** — extracted facts, decisions, discoveries, fixes
3. **knowledge surface** — wiki pages, search results, related-item views, briefings

That promotion step is where quality lives.

If you ingest everything blindly, your wiki turns into sludge. If you promote selectively, it becomes a trusted operating surface.

### Behavioral Rule: Write It Down

This is critical enough to deserve its own section in AGENTS.md:

> If you want to remember something, WRITE IT TO A FILE. "Mental notes" don't survive session restarts. Files do.

When someone says "remember this" → write to today's daily note immediately. Not "later." Not "at the end of the conversation." NOW. The number of times an agent says "I'll remember that" and then doesn't because the session ended is... all of them.

## MEMORY.md — Auto-Generated Index

### What It Is

MEMORY.md is NOT a file the agent writes to manually. It's auto-generated by your memory pipeline, ideally using OpenClaw's native local memory stack or a custom extractor, and that pipeline should:

1. Maintain a SQLite database of observations
2. Extract new observations from daily note files and session activity
3. Generate a semantic index (MEMORY.md) with the most relevant observations
4. Rank observations by recency, importance, and relevance

### How It Works

```
Daily notes (memory/YYYY-MM-DD.md)   Session/tool activity
         ↓                                   ↓
         └──────────── extraction / synthesis ────────────┘
                               ↓
                  SQLite observation database
                               ↓
      search / ranking / recency / relevance selection
                               ↓
           MEMORY.md (top observations, auto-generated)
```

The extraction process identifies distinct observations (decisions, discoveries, changes, errors), stores them with metadata, and indexes them for retrieval.

In a current OpenClaw-native setup, local memory search should be the baseline and MEMORY.md should be refreshed by your memory pipeline on session start, on a recurring schedule, or both. The exact trigger matters less than the invariant: MEMORY.md should stay fresh and should not become a hand-maintained scrapbook.

### Dreaming Is Additive, Not the Baseline

If you enable `memory-core` dreaming, treat it as a higher-level synthesis layer, not as the entire memory system.

A practical split is:
- **local memory search** for durable retrieval
- **SQLite + FTS/vector indexes** for search quality and ranking
- **MEMORY.md** for operator-facing digest
- **dreaming** for periodic synthesis, clustering, or pattern formation

This framing matters because dreaming is useful, but it is not a 1:1 replacement for the rest of the memory stack by itself.

### Observation Database Schema

The SQLite layer is the real engine of the memory system. A practical schema looks like this:

```sql
CREATE TABLE observations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    memory_session_id TEXT NOT NULL,
    project TEXT NOT NULL,
    text TEXT,
    type TEXT NOT NULL,
    title TEXT,
    subtitle TEXT,
    facts TEXT,
    narrative TEXT,
    concepts TEXT,
    files_read TEXT,
    files_modified TEXT,
    prompt_number INTEGER,
    discovery_tokens INTEGER DEFAULT 0,
    created_at TEXT NOT NULL,
    created_at_epoch INTEGER NOT NULL,
    content_hash TEXT
);
```

Typical supporting tables:

- `sdk_sessions` — session metadata and session↔memory mapping
- `observations_fts` — full-text search index (FTS5)
- `session_summaries` — synthesized per-session summaries
- `user_prompts` — prompt history / retrieval context

A practical FTS index looks like:

```sql
CREATE VIRTUAL TABLE observations_fts USING fts5(
    title,
    subtitle,
    narrative,
    text,
    facts,
    concepts,
    content='observations',
    content_rowid='id'
);
```

This is why the system works so well:
- **markdown is the source narrative**
- **SQLite is the retrieval engine**
- **MEMORY.md is the compressed operator-facing digest**

If you want a minimal runnable starting point, see:
- `reference/scripts/mem-extract`
- `reference/scripts/mem-search`
- `docs/validation.md`

### Setup

```bash
# Prefer OpenClaw native local memory as the base layer
# Verify health with: openclaw memory status --deep
# Refresh MEMORY.md on session start, on a cron, or both

# Your memory stack needs:
# - Path to your workspace
# - Path to the SQLite database (for example, data/memory.db)
# - Path to MEMORY.md (workspace root)
# - Clear promotion rules for what becomes durable memory
```

## Setup Guide: Building the Memory Stack

The right order is:

### 1. Define your sources
Choose what can feed memory:
- daily notes
- project files
- task tracker records
- docs / READMEs
- contract or execution logs
- selected external research
- optional chat summaries

### 2. Define your storage layers
Use separate layers for separate jobs:
- **raw logs** for capture
- **SQLite observations** for retrieval
- **markdown digests** for human inspection
- **project files** for ongoing structured work

### 3. Define extraction rules
Write down what gets promoted into durable memory:
- decisions
- recurring fixes
- preferences
- environment facts
- major changes
- error → root cause → fix chains

If a piece of information would help a future session succeed faster, it probably belongs in memory.

### 4. Define retrieval paths
Support at least four ways to access knowledge:
- keyword search
- semantic retrieval / ranking
- relationship traversal (related items)
- briefings / context packs for agents

### 5. Define the UI surface
The memory system becomes an LLM wiki when you expose it through a readable interface:
- search page
- entity/detail pages
- backlinks / related items
- timelines
- source tracing
- recent changes
- "brief me on this" summaries

### 6. Define governance
Decide early:
- what is private vs shared
- which sources are trusted enough to ingest
- who can write memory directly
- what gets archived vs kept hot
- how secrets are excluded

For a step-by-step implementation checklist, see `docs/setup-memory-system.md`.

### Querying Observations

For searching past observations beyond what's in MEMORY.md:

```bash
# Search observations by keyword
mem-search "docker networking"

# Search with date range
mem-search "trading" --after 2026-03-01

# Get specific observations by ID
get-observations 42 43 44
```

Build your own `mem-search` script or wrapper around the native memory surfaces. The exact schema can vary, but the pattern should stay the same: observations are structured rows with enough metadata to support search, ranking, provenance, and reconstruction.

## Memory Segmentation — Security

MEMORY.md contains personal context — decisions, preferences, people, projects. This is sensitive.

**Rule: MEMORY.md only loads in private sessions.**

- Direct chat with your human → MEMORY.md loads ✅
- Group chats, Discord channels → MEMORY.md does NOT load ❌
- Shared sessions with other users → MEMORY.md does NOT load ❌

This prevents data exfiltration via social engineering. If someone in a group chat asks "what do you know about [person]?", the agent literally doesn't have that context loaded.

Implement this in your session startup logic or via the `agent-firewall` hook (see Chapter 4).

## Mandatory Memory Search

Before answering questions about the past, your agent should search memory files rather than relying on whatever fragments might be in its context window.

**Trigger phrases that require memory search:**
- "remember when", "did we", "wasn't there", "what about"
- "who is [name]", "tell me about [person]"
- "when did", "how long ago", "last time"
- "what was", "didn't we", "I thought we"

**The rule:** If the agent is about to answer from "memory" without actually checking files — STOP. Run a search first. The agent's confidence about past events is often wrong. Files are truth.

This is a behavioral instruction in AGENTS.md, not a technical enforcement. But it's one of the most important patterns for accuracy.

## Heartbeat State Tracking

The agent tracks which periodic checks it has performed in `memory/heartbeat-state.json`:

```json
{
  "lastChecks": {
    "email": 1712131200,
    "calendar": 1712127600,
    "weather": null,
    "system_health": 1712120400
  },
  "lastHeartbeat": 1712131200,
  "checksToday": 4
}
```

This prevents redundant checks (don't scan email if you checked 10 minutes ago) and ensures nothing falls through the cracks (weather hasn't been checked in 2 days).

Cross-reference: see Chapter 6 for heartbeat vs cron patterns.

## Memory Maintenance

During heartbeats (every few hours), the agent should periodically:

1. **Read recent daily notes** — scan the last 2-3 days for gaps
2. **Fill gaps** — if something happened that wasn't captured, write it now
3. **Synthesize** — identify patterns across days (e.g., "Docker issues keep recurring after updates")
4. **Clean up** — note stale project states, completed TODOs that weren't marked done

This is the agent equivalent of a human reviewing their journal. It takes 30 seconds of processing time and prevents context drift.

## Retention & Archival

Default to **archive-first**, not deletion-first.

If older notes are not needed in the active working set, move them out of the hot path rather than deleting them. In brownfield migrations this matters even more: old files often contain the only surviving explanation for why a system behaves strangely.

If tracked memory or note files were previously deleted but may still carry useful context, restore them first, review them, then archive if they are obsolete. That preserve-review-archive sequence is safer than guessing from a partial history.

Daily notes accumulate. Over months, you'll have hundreds of files. Strategies:

- **Keep recent notes accessible** (last 30 days in `memory/`)
- **Archive older notes** (move to `memory/archive/YYYY/MM/` or compress)
- **The SQLite database persists all observations** regardless of file archival
- **MEMORY.md auto-regeneration** means it stays relevant even as daily notes age out

Don't delete old notes — archive them. You never know when you'll need to look up what happened three months ago.

## What to Build

- [ ] Set up the `memory/` directory (done by `setup.sh`)
- [ ] Enable a durable memory pipeline, preferably OpenClaw native local memory plus a MEMORY.md refresh path
- [ ] Set up hourly extraction cron (or OpenClaw cron job)
- [ ] Build a `mem-search` script that queries the SQLite observation database
- [ ] Add memory segmentation logic to your session startup or firewall hook
- [ ] Create `memory/heartbeat-state.json` with initial empty state
- [ ] Write your first daily note manually to seed the system
- [ ] Configure MEMORY.md auto-generation on session start, on a schedule, or both
- [ ] Expose the memory layer through a searchable dashboard knowledge page or wiki UI
- [ ] Add source tracing so every summary can point back to the underlying note, task, doc, or observation
- [ ] Document promotion rules so your knowledge graph stays high-signal instead of becoming a dumpster

Related docs:
- `docs/llm-wiki.md`
- `docs/setup-memory-system.md`

---

*Previous: [Chapter 1 — Foundations](01-foundations.md) | Next: [Chapter 3 — Task Management](03-task-management.md)*
