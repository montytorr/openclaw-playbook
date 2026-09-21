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
   - expose the memory layer as an LLM wiki / knowledge page

3. **Task tracking**
   - check the authoritative task system before work
   - claim/checkpoint durable work and close with a resolution

4. **Timing + enforcement**
   - heartbeat for batched checks
   - cron for exact timing / isolated runs
   - hooks to guard dangerous tool calls

## Why This Matters

An autonomous agent without memory is just a very articulate goldfish.

The point of this stack is not merely to save notes. It is to build a **memory system** that can become an **LLM wiki**:
- humans can browse it
- agents can retrieve from it
- decisions survive context resets
- projects accumulate knowledge instead of repeating explanations

That is what turns an agent from session-based assistance into compounding operational leverage.

## Minimum Viable Loop

```bash
# 1. Start work (Cairn example; use your deployment's authority)
cairn check "fix thing"
cairn add "Fix thing" --project <PROJECT> --type bug --priority medium
cairn claim <REF>

# 2. Write memory during work
echo "# 2026-04-04" >> memory/2026-04-04.md
echo "- Fixed issue X because Y" >> memory/2026-04-04.md

# 3. Extract/search memory
reference/scripts/mem-extract
reference/scripts/mem-search "issue X"

# 4. Finish work
cairn done <REF> --resolution "What changed" --kind fixed
```

## Model routing

- Main agent: `<PRIMARY_MODEL>` with an intentional thinking budget
- Cron/reactors: `<ROUTINE_MODEL>` with low/off thinking where appropriate
- Mechanical loops: a verified low-cost model, with thinking disabled/off
- Sub-agents: `thinking=off` unless reasoning is actually needed

Model IDs are account- and release-specific. Verify aliases, provider health, and
fallback behavior live; never treat a model name in this document as current.

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
- scheduled recovery sweep cleans up missed or retained wake events

## Validation Quick Checks

- Can the agent write a daily note?
- Can the authoritative task system show current work?
- Can heartbeat wake and return `HEARTBEAT_OK`?
- Can a dangerous tool call be blocked by a hook?
- Can a completed task be found later via memory search?

If yes, you have infrastructure — not just prompts.

## If You Build One Extra Thing

Build the knowledge page.

Even a simple version pays off:
- search across notes, tasks, and docs
- show related items
- show sources
- let a human ask "what do we know about this?"

That is the first real version of the LLM wiki.
