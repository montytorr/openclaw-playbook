# LLM Wiki

The memory system should not stop at storage.

The real goal is to turn durable memory into an **LLM wiki**: a searchable, browsable knowledge surface for both humans and agents.

## What It Is

An LLM wiki is the human-facing layer on top of your memory stack.

Think of the layers like this:

- **Memory** = purpose
- **Knowledge graph** = structure
- **LLM wiki** = interface

If the memory system preserves context, the wiki makes that context usable.

## Why It Matters

Without a wiki layer, teams end up with:
- notes nobody revisits
- task logs nobody can search well
- docs disconnected from execution
- agent summaries that cannot be traced back to evidence

With a wiki layer, you get:
- searchable institutional memory
- fast briefings on projects, people, issues, and decisions
- linked context across tasks, docs, notes, and events
- better agent handoffs
- more trust because source material is visible

## What Should Appear in the Wiki

Good candidates:
- project pages
- task-linked knowledge
- durable observations
- decision summaries
- environment facts
- people / company context
- contract or workflow history
- selected external research with provenance

Bad candidates:
- secrets
- low-signal chatter
- duplicate junk
- unfiltered raw logs as the main experience

## Core UX Patterns

### 1. Global Search
Search across:
- notes
- observations
- tasks
- project files
- docs
- people
- events

### 2. Entity Pages
Each major object should have a detail page or panel:
- summary
- recent updates
- related items
- sources
- timeline

### 3. Backlinks / Related Items
A page becomes far more useful when it answers:
- what is connected to this?
- what does this affect?
- what else should I read next?

### 4. Briefings
Users and agents should be able to ask for compact briefings such as:
- brief me on this project
- what do we know about this customer?
- summarize prior decisions about this issue

### 5. Source Tracing
Every generated summary should point back to underlying evidence.

If you cannot answer "where did this come from?" the wiki will stop being trusted.

## Design Rules

- **Summaries first, detail underneath**
- **Traceability over magic**
- **Relationships visible by default**
- **Read-heavy is fine** — write paths can stay elsewhere
- **Practical graph, not ontology theater**

## Knowledge Graph Underneath

The wiki works best when the memory layer exposes connected entities.

Useful node types:
- memory
- note
- task
- project
- doc
- decision
- person
- event
- contract
- research item

Useful edges:
- related to
- mentioned in
- derived from
- blocks
- owned by
- decided by
- source of truth for
- last updated by

You do not need a giant formal schema on day one. Start with the entities your agent already touches every day.

## Minimum Viable LLM Wiki

A tiny but useful version includes:
- one search box
- one knowledge detail page
- source links
- related items
- recent updates

That alone is enough to make the memory system visible and useful.

## Recommended Dashboard Positioning

If your dashboard has a `knowledge` page, document it plainly:

> The Knowledge page is the memory system surfaced as an LLM wiki.

That sentence tells operators what the page is for and why it matters.

## Related Reading

- `playbook/02-memory-system.md`
- `playbook/08-dashboard.md`
- `docs/setup-memory-system.md`
