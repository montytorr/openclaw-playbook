# Brownfield Adoption Template

Use this when adopting the playbook into an already-active environment.

## 1. Baseline Snapshot

```markdown
# Brownfield Baseline — YYYY-MM-DD

## Git
- Branch:
- Dirty tracked files:
- Untracked files/directories worth noting:

## Existing task surface
- CLI/API name:
- Primary commands/endpoints:
- Stable IDs:
- Downstream dependencies:

## Existing memory surface
- Sources:
- Highest-signal source:
- Known low-signal/noise sources:

## Existing hooks/plugins
- Hook/plugin:
- Trigger/event:
- Enforcement level:
- Known overlap/conflicts:

## Existing automation
- cron/systemd/CI/webhooks currently in play:

## Validation path
- Tests/scripts:
- Manual smoke checks:
- Known pre-existing dirt/exceptions:
```

## 2. Task Field Mapping Template

| Existing field/system | Playbook concept | Migration convention | Notes |
|---|---|---|---|
| category | category/project | keep as category unless it actually names a long-lived project | |
| input | input | request / reason / trigger | |
| output | output | result / delivery / accomplishment | |
| description | input/output split | split legacy free-text into request vs result where possible | |
| notes | notes/memory | keep context out of the title | |
| priority | priority | preserve if already meaningful | |
| assignee | owner/session context | optional in single-operator setups | |

## 3. Status Mapping Examples

| Legacy status | Playbook status | Notes |
|---|---|---|
| planned | planned | |
| todo | planned | |
| backlog | planned | backlog wording can remain in UI/docs |
| queued | planned | |
| in_progress | in-progress | |
| doing | in-progress | |
| active | in-progress | |
| done | done | |
| complete | done | |
| blocked | planned or wrapper metadata | keep extra semantics outside core model if needed |
| cancelled | archive/delete by local policy | don't force into done |

## 4. Wrapper-vs-Replace Decision Path

- Does the current CLI/API already cover create/start, update, list/search, and stable IDs?
- Can a thin wrapper normalize naming and output shape?
- Do downstream dashboards or automations depend on current behavior?
- Would replacement break operator muscle memory?
- Is the current interface so inconsistent that the wrapper becomes fiction?

Decision rule:
- thin wrapper gives you most of the contract -> **wrap**
- wrapper would simulate half the system -> **replace**

## 5. Memory Ingestion Tiers

### Tier A — ingest first
- project decisions
- postmortems
- durable user preferences
- recurring infrastructure fixes
- environment facts that stay true

### Tier B — ingest second
- task completions
- sprint summaries
- structured meeting notes
- issue/PR summaries

### Tier C — ingest last or skip
- greetings
- bootstrap chatter
- repetitive heartbeat noise
- setup confirmations with no durable value

## 6. Archive-First Cleanup Matrix

| Condition | Action |
|---|---|
| Active and referenced | Keep |
| Obsolete but historically useful | Archive |
| Disposable duplicate/generated noise | Delete |
| Uncertain | Archive first |

Special case:
- previously deleted tracked files with possible value -> restore first, then archive if obsolete

## 7. Hook Hardening Ladder

| Level | Behavior |
|---|---|
| Informational | log/classify only |
| Warning/logging | visible warnings and audit trail |
| Blocking (`before_tool_call`) | enforce high-confidence rules |

## 8. Brownfield Validation Checklist

- [ ] Existing task flow still works
- [ ] Existing memory ingestion still works
- [ ] New docs match current behavior
- [ ] Hook changes do not block known-good workflows unexpectedly
- [ ] Archive locations are discoverable
- [ ] Navigation/links remain coherent
- [ ] Validation passes with known repo dirt documented
