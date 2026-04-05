# Brownfield Migration Case Study: Active Workspace Adoption

This is a deliberately small, realistic migration sketch — the kind of adoption you do in a workspace that is already alive, already messy, and already useful.

## Before State

The operator already had a functioning workspace with:
- a local `task-shell` wrapper feeding an internal task API
- a dashboard reading the existing task records directly
- daily notes in `memory/`
- a handful of old scripts and bootstrap scraps sitting in the repo root
- an always-dirty git status because generated notes and one local config tweak were intentionally uncommitted

Nothing was pristine. That was the point.

## Adoption Decisions

The team chose to:
- **adopt in place**, not rebuild the workspace from scratch
- **wrap the existing task interface** instead of replacing it on day one
- **archive before delete** for obsolete scripts and bootstrap leftovers
- **backfill only Tier A memory first** from daily notes and decision-heavy docs
- **validate inside the dirty repo reality** instead of waiting for a mythical clean branch

## Task Mapping

The existing task API used:
- `summary` for title
- `request` for operator intent
- `bucket` for category
- `urgency` for priority
- `state` values of `todo`, `doing`, and `complete`

The playbook wrapper mapped that to:
- `title` -> `summary`
- `input` -> `request`
- `category` -> `bucket`
- `priority` -> `urgency`
- `planned` / `in-progress` / `done` -> `todo` / `doing` / `complete`

That preserved the downstream dashboard and operator muscle memory while making the playbook contract usable immediately.

## Archive-First Cleanup

During adoption, the operator found three stale artifacts:
- `scripts/task-shell-old`
- `bootstrap-notes.md`
- `hooks/task-reminder-v0.ts`

Instead of deleting them, they were moved into `archive/` with a short migration note:
- the old task wrapper stayed available for reference during the transition
- the bootstrap notes stayed searchable in case setup assumptions mattered later
- the retired hook prototype remained inspectable when tuning the new enforcement path

That left the active tree cleaner without destroying the trail.

## Memory Backfill Choices

First-wave ingestion only included:
- decision-heavy daily notes
- infra incident notes
- operator preference notes
- a short migration log

It explicitly skipped:
- greeting-heavy chat exports
- session-start boilerplate
- repeated "all good" heartbeat noise
- old setup transcripts that explained nothing durable

Result: retrieval stayed biased toward useful operational memory instead of conversational filler.

## Validation Gates

The migration was considered good enough when these passed:
- the existing task flow still worked through the wrapper
- archived artifacts were easy to find under `archive/`
- selective memory extraction indexed decision bullets, not junk exports
- the brownfield verifier passed even with known repo dirt present
- generic starter verification still passed

## Outcome

The workspace kept its existing shape, dashboards, and habits — but gained a clearer playbook contract, archive discipline, and a cleaner memory ingestion boundary.

No big-bang rewrite. No fake clean-room reset. Just a safer, more legible active workspace.
