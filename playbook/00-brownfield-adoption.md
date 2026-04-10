# Chapter 0: Brownfield Adoption

Most teams do **not** get to start with a clean room.

They already have:
- a dirty repo
- some scripts that kind of work
- old notes and chat logs
- half-built hooks
- cron jobs nobody fully trusts
- existing CLIs or APIs that the agent needs to live with

If you pretend you're greenfield when you're not, you'll break useful things, erase context, and create a migration everyone resents.

This chapter is the practical path for adopting the playbook into an already-active environment.

## The Brownfield Rule

**Default to adopt-in-place, archive-first, and reversible changes.**

That means:
- take a baseline snapshot before touching behavior
- avoid forcing a pristine repo before you can validate anything
- wrap existing tooling before replacing it
- archive before deleting
- ingest high-value memory first, not noise
- harden hooks in stages instead of flipping to hard-blocking on day one

## Reality-Check Preflight

Do this before you copy a single template file.

### Environment preflight checklist

- [ ] **Existing task API or task CLI?**
  - SQLite CLI, REST API, Linear sync, GitHub Issues bridge, or something else?
  - Decide whether OpenClaw should call it directly, wrap it, or replace it later.
- [ ] **Existing memory corpus?**
  - Daily notes, Obsidian vault, Slack exports, issue comments, postmortems, changelogs?
  - Identify what is signal vs bootstrap/greeting/noise.
- [ ] **Existing hooks/plugins?**
  - What already intercepts commands, messages, or session startup?
  - Document order of execution and any overlapping enforcement.
- [ ] **Dirty git state?**
  - Uncommitted tracked files, local-only patches, generated files, untracked scripts?
  - Know what is intentionally dirty before migration starts.
- [ ] **Existing automation already in place?**
  - cron, systemd timers, CI jobs, webhooks, launchd, Docker restart hooks?
  - Avoid duplicating something that already works.
- [ ] **Existing CLI/API surface the agent depends on?**
  - Wrapper candidates, compatibility risks, auth assumptions, rate limits.
- [ ] **Rollback path defined?**
  - Can you restore previous behavior in minutes, not hours?

If you cannot answer those seven questions, you're not ready to "install the playbook." You're ready to inventory reality.

## Runtime Truth Beats Manifest Theory

In brownfield systems, docs, manifests, and plugin metadata are hints, not proof.

What matters is what the live runtime actually does.

That means:
- read the real implementation path when behavior matters
- verify live config conditions directly
- check exporters, collectors, and external integrations with real signals
- treat "the manifest implies it should work" as unverified until the runtime agrees

This matters most for:
- observability wiring
- hook ordering and enforcement points
- plugin enablement
- wrappers around existing CLIs or APIs
- any migration that claims a system is now "covered"

If there is tension between the docs and the runtime, trust the runtime and fix the docs.

## Step 1: Take a Baseline Snapshot

Before changes, capture the environment as it actually exists.

### Baseline snapshot checklist

- [ ] `git status --short`
- [ ] current branch name
- [ ] latest 5-10 commits
- [ ] list of untracked files that matter
- [ ] current cron/systemd/automation inventory
- [ ] hook/plugin inventory
- [ ] task system entry points
- [ ] memory sources and approximate volume
- [ ] current validation method (tests, smoke scripts, manual checks)

The goal is not paperwork. The goal is **reconstruction**.
If the migration goes sideways, you need to know what "before" looked like.

### Recommended snapshot artifact

Create a migration note such as:

```markdown
# Brownfield Baseline — 2026-04-05

## Git
- Branch: main
- Dirty tracked files: 4
- Untracked directories: scripts/tmp/, notes/import/

## Existing task system
- `task` shell wrapper -> python CLI
- Dashboard reads SQLite directly

## Existing memory sources
- Obsidian vault (high signal)
- Discord export (mixed signal)
- bootstrap notes from initial install (low signal)

## Existing hooks
- before_tool_call: secret scan only
- after_tool_call: auto-commit draft

## Existing automation
- cron: memory extraction hourly
- systemd: dashboard restart watcher

## Validation path
- `reference/scripts/verify`
- manual dashboard smoke test
```

Put the file wherever your environment keeps migration notes or project docs. The point is to create a reference point before you start "improving" things.

## Step 2: Dirty Repo Handling

A brownfield repo is often dirty for legitimate reasons:
- generated state intentionally excluded from commits
- experiments parked locally
- long-lived uncommitted config tweaks
- documentation already mid-edit

Do **not** make "pristine repo" a prerequisite for adoption.
That is how migrations stall forever.

### Recommended stance

1. **Inspect the dirt**
2. **Classify it**
3. **Fence your migration changes**
4. **Validate within that reality**

### Dirty state triage

| Repo state | Recommended move |
|---|---|
| Small intentional local edits | Keep them, document them, migrate around them |
| Unknown tracked changes | Review before layering new docs or scripts on top |
| Large unrelated WIP | Move migration work to a dedicated branch |
| Generated artifacts polluting status | fix `.gitignore` or route outputs elsewhere |
| Deleted tracked files you may still need | restore first, then archive if obsolete |

### Restore-then-archive for previously deleted tracked files

If tracked files were deleted locally but may still contain context or implementation clues, restore them **before** deciding whether they should disappear.

Pattern:
1. restore the deleted tracked file from git
2. review whether it still has reference value
3. if obsolete, move it to an archive location with a short note
4. only then remove or ignore it from the active path

Deletion first destroys evidence. Restore-then-archive keeps history inspectable.

## Step 3: Adopt-in-Place vs Replace

This is the fork most teams screw up.

### Adopt-in-place when:
- the existing CLI/API already works and is trusted
- downstream dashboards or scripts already depend on it
- the data model is ugly but understandable
- you need quick wins without service interruption
- migration risk is higher than current pain

### Replace when:
- the existing interface is actively blocking the playbook model
- no stable contract exists
- every integration is bespoke and fragile
- auth/rate-limit behavior is broken beyond repair
- you already know you need a new schema or execution model

### Strong default

**Adopt in place first. Replace later only if the wrapper becomes the problem.**

In brownfield environments, wrapper layers buy you time, reversibility, and validation.

## Step 4: Use a Migration Branch

Even for docs-heavy adoption, use a dedicated branch when the environment is already active.

Recommended names:
- `migration/openclaw-playbook`
- `adoption/brownfield-bootstrap`
- `docs/playbook-brownfield`

Why:
- keeps unrelated dirt out of the review
- makes the migration diff legible
- gives you a rollback boundary
- lets you validate without pretending main is pristine

### Branch strategy

- branch from the real working branch, not an imaginary clean state
- document known pre-existing dirt in the baseline snapshot
- keep migration commits scoped and boring
- merge when the docs + validation are coherent, not when the entire repo is suddenly perfect

## Brownfield Verification Stack

Verification should be treated as a first-class adoption artifact, not a nice-to-have after the docs feel polished.

A practical live-workspace stack looks like this:

1. `integrity-check init` to baseline protected files
2. `integrity-check check` to confirm no unexpected drift
3. `verify-memory-readiness` to confirm the memory pipeline is minimally real
4. `verify` to prove the starter loop still works
5. `verify-brownfield` to validate adopt-in-place assumptions
6. `verify-local` to run the stack together once the workspace has been wired up

The point is not the exact names. The point is that a rollout should have repeatable checks for:
- protected-file integrity
- memory readiness
- generic loop health
- brownfield-specific assumptions

## Step 5: Validate Without Requiring a Pristine Repo

Validation in brownfield should answer one question:

**Did the new playbook layer improve safety and operator clarity without breaking current workflows?**

Not:
- "Did we eliminate all historical weirdness?"
- "Did git status become empty?"
- "Did every old script get rewritten?"

### Brownfield validation checklist

- [ ] existing task flow still works
- [ ] existing memory ingestion still runs
- [ ] new docs match actual current behavior
- [ ] hook changes do not block known-good workflows unexpectedly
- [ ] archive paths are discoverable and documented
- [ ] repo navigation still makes sense after additions
- [ ] smoke tests pass, even with known unrelated repo dirt documented

Document known exceptions instead of pretending they don't exist.

Example:

```markdown
## Validation notes
- `reference/scripts/verify` passes
- repo still has 2 unrelated modified files from pre-existing local ops
- no nav/link regressions after adding brownfield chapter
- task CLI examples match current wrapper behavior
```

## Adapter Template: Map What You Have Before You Rebuild It

Brownfield adoption gets easier when you map old concepts to playbook concepts explicitly.

### Task field mapping template

| Existing field/system | Playbook concept | Migration convention | Notes |
|---|---|---|---|
| `category` | `project` or `category` | Keep as `category` if already meaningful; map to project file when it identifies a long-lived workstream | Don't invent new taxonomy unless needed |
| `input` | task input | Treat as "why/request" | Preserve raw operator phrasing if useful |
| `output` | task output | Treat as delivered result / outcome | Prefer concrete result over generic status text |
| `description` | input/output split | If one field holds both, split request into `input` and result into `output` during migration | Don't lose the original text |
| `notes` | project notes or memory note | Keep operational chatter out of task title | Use for context, not status |
| `priority` | priority | Preserve if already in use | Avoid remapping unless semantics are broken |
| `assignee` | owner/session context | Optional in single-operator setups | Useful if multiple agents or humans act |
| `created_by` | provenance | keep if available | Helps audit imported tasks |

### Description convention template

If the legacy system only has one free-text field:

- **Input convention:** what was requested, why this exists, or what problem triggered it
- **Output convention:** what changed, what shipped, what was fixed, what was learned

Practical split:

```text
input  = request / problem / trigger
output = result / delivery / fix / decision
```

### Status mapping examples

| Legacy status | Playbook status | Notes |
|---|---|---|
| `planned` | `planned` | direct mapping |
| `todo` | `planned` | direct backlog equivalent |
| `backlog` | `planned` | keep backlog semantics in UI/docs if useful |
| `queued` | `planned` | unless execution has already started |
| `in_progress` | `in-progress` | direct mapping |
| `doing` | `in-progress` | direct mapping |
| `active` | `in-progress` | only if actual work is underway |
| `done` | `done` | direct mapping |
| `complete` | `done` | direct mapping |
| `blocked` | `planned` or external blocker note | playbook keeps status model intentionally simple |
| `cancelled` | archive/delete by local policy | usually do not force into `done` |

If your existing system depends heavily on `blocked` or `cancelled`, keep that in the source system or wrapper metadata. Do not bloat the playbook status model unless you genuinely need the extra state.

### Wrapper-vs-replace decision path

Use this before rebuilding an existing task CLI or API.

1. **Does the current interface already cover the playbook minimum?**
   - start/create
   - update/status
   - list/search
   - stable IDs
2. **Can a thin wrapper normalize names and outputs?**
3. **Do existing dashboards/automations depend on current behavior?**
4. **Will replacement break operator muscle memory?**
5. **Is the current system so inconsistent that the wrapper becomes a lie?**

Decision rule:
- if a thin wrapper gives you 80% compatibility, **wrap it**
- if the wrapper must simulate half the system, **replace it**

## Archive-First Cleanup

When adopting the playbook into an existing environment, **archive-first should be the default cleanup strategy**.

Deletion is cheap. Reconstructing why something existed is expensive.

### Default order of operations

1. **Keep** if still active or still referenced
2. **Archive** if not active but still useful for history, rollback, or pattern reference
3. **Delete** only when it is clearly disposable and already represented elsewhere

### Keep / archive / delete guide

| Condition | Action |
|---|---|
| actively used by scripts, hooks, crons, dashboards, or humans | Keep |
| obsolete in active flow but useful for history or migration reference | Archive |
| generated noise, duplicate artifact, or clearly disposable temp output | Delete |
| uncertain whether still needed | Archive first |

### Good archive targets

- old scripts replaced by wrappers
- previous config examples
- retired prompt/bootstrap drafts
- historical task exports
- unused but informative hook prototypes
- migration notes and before/after snapshots

### Archive note pattern

When you archive something, leave a one-line reason in the destination README or migration note:

```markdown
- Archived `scripts/task-old` on 2026-04-05 after wrapper adoption; kept for reference because dashboard output format depended on it during transition.
```

That tiny sentence saves future-you a forensic weekend.

## Memory Ingestion Tiers for Brownfield Migration

Do **not** dump every old note, greeting, and bootstrap artifact into the memory system on day one.

That creates a memory corpus full of noise and teaches the agent to retrieve junk.

### Tier A — ingest first

High-signal operational memory:
- project decisions
- postmortems
- recurring infrastructure fixes
- stable user preferences
- environment facts that remain true across sessions
- important people/context actually needed for work

### Tier B — ingest second

Useful but less critical:
- task completions
- sprint summaries
- changelogs
- structured meeting notes
- issue/PR summaries
- operator-written runbooks

### Tier C — ingest last or skip

Low-signal material:
- bootstrap chatter
- greeting messages
- empty acknowledgements
- generic heartbeat noise
- repeated setup confirmations
- low-context chat logs with no decisions

### Brownfield ingestion sequence

1. ingest Tier A sources first
2. validate retrieval quality
3. add selected Tier B sources
4. only ingest Tier C if you have a compelling retrieval use case

### How to avoid indexing noise first

Before extraction, filter out:
- files dominated by greetings or startup boilerplate
- repeated "session start" notes with no decisions
- status pings that contain no durable information
- generated exports that duplicate cleaner sources elsewhere

A practical heuristic:

**If a file would not help a future operator answer "what changed, why, or what matters?" it should not be first-wave memory ingestion.**

## Hook Hardening Maturity Ladder

Do not take a fragile brownfield environment and jump straight to hard-blocking everything. That is how you create operator backlash.

Use a maturity ladder.

### Level 1 — Informational

- classify risky actions
- log what would have happened
- surface audit trails
- no blocking yet

Use this when you are still learning real traffic patterns.

### Level 2 — Warning / Logging

- continue logging
- add explicit warnings for suspicious or high-risk actions
- require acknowledgement in docs or operational review
- still avoid breaking known-good flows unless clearly dangerous

Use this when you understand the baseline and want visibility with light friction.

### Level 3 — Blocking at `before_tool_call`

- block credential leaks
- block destructive commands or require approval
- enforce high-confidence safety rules at the platform edge

Use this only after Levels 1 and 2 prove your rule set is accurate enough.

### Ladder guidance

| Maturity level | Best for | Main risk |
|---|---|---|
| Informational | early brownfield adoption | too passive if left forever |
| Warning/logging | active tuning period | alert fatigue |
| Blocking | stable, understood workflows | false positives that halt real work |

The correct sequence is usually:

```text
informational -> warning/logging -> blocking
```

Not because blocking is weak. Because premature blocking is sloppy.

## What “Good” Brownfield Adoption Looks Like

A good migration does **not** erase the past.
It makes the current environment more legible, safer, and easier to evolve.

Success looks like:
- your baseline is documented
- your existing tooling is mapped before it is replaced
- cleanup preserves history via archives
- memory ingestion favors signal over noise
- hooks harden in stages
- validation works even with known repo dirt
- runtime behavior is verified directly instead of inferred from manifests
- delegation is governed and post-subagent output is checked before trust is granted

That's adulthood, not greenfield cosplay.

---

*Next: [Chapter 1 — Foundations](01-foundations.md)*
