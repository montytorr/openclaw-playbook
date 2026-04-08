# Setup Memory System

This guide explains how to set up the memory stack behind the OpenClaw playbook.

## Objective

Build a memory system that:
- survives session resets
- preserves decisions and discoveries
- supports search and ranking
- powers an LLM wiki / dashboard knowledge page
- stays high-signal instead of turning into junk storage

## Step 1: Define Sources

Start with the sources that actually contain durable signal:
- `memory/YYYY-MM-DD.md`
- `projects/*.md`
- task records
- docs / READMEs
- selected execution or contract records
- selected external research

Do **not** start by ingesting every log you can find.

## Step 2: Separate Storage Layers

Use different layers for different jobs:

### Raw capture
Examples:
- daily notes
- raw logs
- session summaries

### Durable observations
Examples:
- extracted facts
- decisions
- discoveries
- root-cause / fix chains

### Human digest
Examples:
- `MEMORY.md`
- project summaries
- dashboard briefings

### Knowledge UI
Examples:
- dashboard knowledge page
- wiki detail pages
- search results

## Step 3: Define Promotion Rules

Write down what deserves promotion from raw notes into durable memory.

Usually yes:
- decisions
- preferences
- environment facts
- recurring fixes
- project milestones
- failure patterns
- important people/context notes

Usually no:
- greetings
- filler chat
- duplicate status pings
- transient noise
- secrets

This step matters more than people think. Quality memory is mostly a curation problem.

## Step 4: Build Extraction

At minimum, your extraction flow should:
1. read new daily notes and selected records
2. identify durable observations
3. store them in SQLite with metadata
4. update or regenerate `MEMORY.md`
5. make observations searchable

A simple cycle can run hourly.

## Step 5: Add Retrieval

Support at least these access patterns:
- keyword search
- date filtering
- semantic ranking if available
- related-item lookup
- briefing generation

If retrieval is weak, the memory system will exist but remain unused.

## Step 6: Expose the Wiki Surface

This is where storage becomes useful.

Your first knowledge page should support:
- search
- detail view
- related items
- source links
- recent updates

That is enough to call it an LLM wiki with a straight face.

## Step 7: Add Governance

Decide early:
- what is private vs shared
- who can write memory
- which sources are trusted
- what gets archived
- what should never be ingested

Also enforce memory segmentation so private memory is not loaded into shared/group contexts.

## Step 8: Maintenance

Memory systems decay unless maintained.

Add recurring routines for:
- review of recent notes
- gap-filling
- deduplication
- archival of stale material
- docs sync when behavior changes

## Recommended First Build

If you want the shortest sane path:

1. write daily notes
2. extract observations into SQLite
3. regenerate `MEMORY.md`
4. build `mem-search`
5. add a dashboard knowledge page with search + sources + related items

That gets you a real memory system quickly.

## Common Failure Modes

- ingesting too much low-signal noise
- no promotion rules
- no source tracing
- private memory leaking into shared contexts
- trying to design a perfect ontology before shipping search

## Success Criteria

You know the setup is working when:
- the agent can answer "what did we decide last time?" from memory, not guesswork
- operators can inspect source material behind summaries
- a new sub-agent can be briefed with real prior context
- the dashboard knowledge page feels useful, not ceremonial

## Related Reading

- `playbook/02-memory-system.md`
- `playbook/08-dashboard.md`
- `docs/llm-wiki.md`
- `schemas/memory-conventions.md`
