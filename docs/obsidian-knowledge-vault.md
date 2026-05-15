# Obsidian Knowledge Vault

Obsidian can be more than a backup target for agent notes. Used well, it becomes a human-readable knowledge vault that the agent can write, query, browse, and graph.

This pattern works especially well when your OpenClaw workspace already has markdown memory files, project docs, dream/synthesis artifacts, and operational runbooks.

## Goals

A good Obsidian integration should provide:

- **sync** — canonical agent files are mirrored into a vault
- **query** — the agent can search the vault without asking the human first
- **graph structure** — links create useful clusters, not a single giant hairball
- **color coding** — graph groups visually separate memory, projects, dreams, and system docs
- **backfill** — historical notes are imported without pretending they are current source of truth
- **idempotence** — sync can run hourly without commit spam or duplicate sections

## Recommended Vault Layout

Use one managed folder inside the vault:

```text
Obsidian vault/
└── Clawd/
    ├── System/          # AGENTS, SOUL, USER, TOOLS, HEARTBEAT, DREAMS, MEMORY
    ├── Memory/          # current canonical daily memory
    │   └── backfill/    # historical retired/archive memory
    ├── Dreaming/        # dream/recall/session-corpus artifacts
    ├── Projects/        # project markdown copied from runtime/repo roots
    ├── Project Hubs/    # generated middle-ground project anchors
    └── OpenClaw/        # selected operational docs/runbooks
```

Keep generated files under a clearly marked managed folder so humans know what is safe to edit.

## Sync Sources

Typical sources:

```text
/root/{AGENTS,SOUL,USER,IDENTITY,TOOLS,HEARTBEAT,DREAMS,MEMORY}.md
/root/memory/*.md
/root/memory/.dreams/**/*.{md,txt,json,jsonl}
/root/backups/memory/**/*.{md,json}
/root/projects/**/*.md
/root/clawd/projects/**/*.md
/root/clawd/docs/**/*.md
/root/clawd/scripts/README.md
```

Rules:

- Treat `/root/MEMORY.md` and `/root/memory` as canonical current memory.
- Put old archives under `Memory/backfill/` so they remain searchable but visually distinct.
- Copy dreaming artifacts as audit/synthesis data, not source-of-truth facts.
- Exclude dependency/build/cache folders: `node_modules`, `.next`, `dist`, `build`, `coverage`, `.venv`, `.pytest_cache`.
- Pull before writing generated files, then commit/push once. Pulling after generation tends to cause Obsidian graph/workspace autostash conflicts.

## Query Helper

Make Obsidian usable by the agent, not just visible to humans.

A minimal helper should support:

- whole-vault or managed-folder search
- markdown/text/json/jsonl/canvas files
- path:line output for quick evidence
- JSON output for agent parsing
- literal search by default, regex as an option

Example interface:

```bash
obsidian-query "dream-filter" --clawd --json
obsidian-query "Apex One" --limit 20
```

Operational rule:

> Query Obsidian without asking when a question may involve notes, project docs, historical/backfilled memory, TODOs, or dreaming/recall artifacts.

Native memory search can remain the first stop for prior-work/history questions. Obsidian is the second source when the answer may live in project docs, backfill, or vault-only notes.

## Graph Color Coding

Obsidian Graph View stores global graph settings in `.obsidian/graph.json`.

`colorGroups` accepts normal Obsidian search queries such as `path:"Clawd/Dreaming"`.

Example managed groups:

```json
{
  "collapse-color-groups": false,
  "colorGroups": [
    { "query": "path:\"Clawd/Memory/backfill\"", "color": { "a": 1, "rgb": 10586239 } },
    { "query": "path:\"Clawd/Memory\"", "color": { "a": 1, "rgb": 5025616 } },
    { "query": "path:\"Clawd/Dreaming\"", "color": { "a": 1, "rgb": 10233776 } },
    { "query": "path:\"Clawd/System\"", "color": { "a": 1, "rgb": 2201331 } },
    { "query": "path:\"Clawd/Projects/runtime\"", "color": { "a": 1, "rgb": 16750592 } },
    { "query": "path:\"Clawd/Projects/repo\"", "color": { "a": 1, "rgb": 16761095 } },
    { "query": "path:\"Clawd/OpenClaw\"", "color": { "a": 1, "rgb": 48340 } }
  ]
}
```

Preserve human-defined color groups that are not managed by your script.

Useful graph physics for this topology:

```json
{
  "showOrphans": false,
  "centerStrength": 0.25,
  "repelStrength": 16,
  "linkStrength": 0.8,
  "linkDistance": 380
}
```

## Linking Strategy: Avoid the Giant Ball

The failure mode is a star topology: thousands of notes all link to `[[project-name]]`, collapsing the graph into one dense ball.

Use a middle-ground strategy.

### 1. Temporal Chains

For daily memory notes:

```text
2026-05-13 ↔ 2026-05-14 ↔ 2026-05-15
```

For historical backfill notes, chain within their own folder. Do not mix old archive chronology into current canonical memory unless that is intentional.

### 2. Project Chronology Chains

For each project, find memory notes that mention the project. Sort them chronologically. Link each note to the previous and next note for that project.

```text
Apex mention on Apr 28 ↔ Apex mention on May 06 ↔ Apex mention on May 15
```

This creates visible project threads across sessions without every note pulling toward one hub.

### 3. Middle-Ground Project Hubs

Create real project hub notes, but use them as anchors, not the only structure.

Each memory note may include a capped project hub link:

```markdown
## Related (generated)
<!-- openclaw:obsidian-related -->
- [[Clawd/Project Hubs/apex-one|apex-one]]
- [[Clawd/Memory/2026-05-14|previous day]]
- [[Clawd/Memory/2026-05-11|apex-one previous]]
<!-- /openclaw:obsidian-related -->
```

Project hub note:

```markdown
---
type: project-hub
generated: true
project: apex-one
memory_mentions: 18
---

# apex-one

Generated by the sync script. This is a middle-ground graph anchor: notes may link here, but chronology/project-chain links carry most of the structure.

## Timeline
- [[Clawd/Memory/2026-04-28|first memory mention]]
- [[Clawd/Memory/2026-05-15|latest memory mention]]

## Project docs
- [[Clawd/Projects/repo/apex-one|apex-one]]
```

### 4. What Not To Link

Do not generate hubs for:

- generic folders: `docs`, `api`, `src`, `templates`, `reports`, `prompts`, `dashboard`, `cli`
- note titles that are really events: `2026-04-29-Production server SSH access`
- OpenClaw reply tags: `[[reply_to_current]]`
- examples or code-like strings: `[["value1", "value2"]]`

Sanitize pseudo-wikilinks in the vault copy only. Do not mutate canonical source files just to satisfy Obsidian.

## Generated Related Sections

Use a bounded generated block:

```markdown
## Related (generated)
<!-- openclaw:obsidian-related -->
- [[Clawd/Project Hubs/civicsignal|civicsignal]]
- [[Clawd/Memory/2026-05-14|previous day]]
- [[Clawd/Memory/2026-05-12|civicsignal previous]]
<!-- /openclaw:obsidian-related -->
```

Regenerate this block on each sync. Keep it idempotent by deleting only the marked generated block before writing a fresh one.

Cap visible links per note. A good default is 15 lines plus an overflow note:

```markdown
- …and 6 more related links
```

## Automation Pattern

Use an OpenClaw cron, not system cron, when you want the sync to run with agent-visible status and failure alerts.

Recommended schedule:

- hourly
- isolated session
- delivery none on success
- failure alert to the operator/system channel

Example run behavior:

```text
obsidian-sync
  -> pull vault
  -> stage generated Clawd folder in temp dir
  -> sanitize pseudo-wikilinks
  -> generate related blocks
  -> rsync managed folders
  -> update graph.json color groups/settings
  -> generate project hubs
  -> git add Clawd .obsidian/graph.json
  -> commit/push if changed
  -> write status JSON
```

Status JSON should include counts:

```json
{
  "systemFiles": 10,
  "memoryFiles": 164,
  "dreamingFiles": 120,
  "projectFiles": 170,
  "projectHubFiles": 16,
  "graphColorGroups": 22,
  "pushStatus": "ok"
}
```

## Verification Checklist

Before declaring it done:

```bash
bash -n scripts/obsidian-sync
scripts/obsidian-sync --dry-run
scripts/obsidian-sync
python3 -m json.tool /path/to/vault/.obsidian/graph.json >/dev/null
python3 -m json.tool data/obsidian-sync-status.json >/dev/null
scripts/obsidian-sync   # should be a no-op if nothing changed
```

Then inspect:

- current memory notes have generated Related sections
- backfill memory notes have generated Related sections
- graph JSON has valid colorGroups
- high-fan-in unresolved wikilinks are gone or intentionally ignored
- no secrets were copied into public docs or commits

## Common Failure Modes

### Commit spam

Usually caused by timestamps in generated README/status files. Keep volatile timestamps out of committed vault files; write them to local status JSON instead.

### Autostash conflicts

Usually caused by pulling after writing generated Obsidian files. Pull before generation.

### Giant graph ball

Usually caused by too many notes linking only to one hub. Add temporal chains and project chronology links; cap hub links.

### Bogus hubs

Usually caused by promoting generic folder names or event titles into notes. Filter aggressively.

### Query exists but agent does not use it

Add the behavior to both the Obsidian skill and your agent instructions:

> Query Obsidian proactively when notes, project docs, backfilled memory, TODOs, or dream/recall artifacts may contain the answer.

## Why This Works

The vault becomes useful to both audiences:

- Humans get a color-coded graph and browsable project/memory structure.
- Agents get a queryable archive with evidence paths.
- Graph links reflect actual work chronology instead of accidental keyword gravity.

That is the difference between "we sync notes to Obsidian" and "Obsidian is our LLM wiki." 
