# Validation Guide

A playbook is only useful if you can prove the loop works.

## Verification-first rollout stack

For a live workspace, do not rely on one feel-good smoke test.

Use a layered verifier stack:

```bash
reference/scripts/integrity-check init
reference/scripts/integrity-check check
reference/scripts/verify-memory-readiness
reference/scripts/verify
reference/scripts/verify-brownfield
reference/scripts/verify-local
```

Why this order:
- `integrity-check` catches protected-file drift early
- `verify-memory-readiness` confirms the memory path is actually usable
- `verify` proves the starter loop still works
- `verify-brownfield` proves adopt-in-place assumptions inside messy reality
- `verify-local` gives you one repeatable local rollout pass once the first pieces exist

## 1. Workspace bootstraps correctly

```bash
./setup.sh
ls AGENTS.md SOUL.md USER.md TOOLS.md SECURITY.md
ls config/openclaw.example.json
```

Expected:
- identity files exist
- config skeleton exists under `config/`

## 2. Task tracking works

```bash
WORKSPACE_ROOT=$(pwd) reference/scripts/task start "Validation task" "Smoke test" other
WORKSPACE_ROOT=$(pwd) reference/scripts/task start "Validation task" "Smoke test" other
WORKSPACE_ROOT=$(pwd) reference/scripts/task list
WORKSPACE_ROOT=$(pwd) reference/scripts/task sprint
WORKSPACE_ROOT=$(pwd) reference/scripts/task show doesnotexist || echo "show exited $? (expected 2)"
WORKSPACE_ROOT=$(pwd) reference/scripts/task delete doesnotexist || echo "delete exited $? (expected 2)"
```

Expected:
- a task id is printed
- repeating the same `task start` does not crash
- the task appears as `in-progress`
- `task sprint` prints grouped output
- not-found mutations/details return exit code `2`

## 3. Memory extraction works

```bash
mkdir -p memory
echo '# 2026-04-04

## 10:00 — Validation
- Decided to keep heartbeat checks lean.
- Fixed a startup path mismatch in setup.sh.' > memory/2026-04-04.md
WORKSPACE_ROOT=$(pwd) reference/scripts/mem-extract
WORKSPACE_ROOT=$(pwd) reference/scripts/mem-extract
WORKSPACE_ROOT=$(pwd) reference/scripts/mem-search "heartbeat"
```

Expected:
- extractor completes
- a second run does not duplicate observations
- search returns the stored observation

## 3.5 Memory readiness verifier exists

```bash
reference/scripts/verify-memory-readiness
```

Expected:
- the workspace has a `memory/` directory
- at least one daily note exists
- extraction/search are functional in the readiness probe

## 4. Hook skeleton behaves as expected

Read `reference/hooks/the-wall.example.ts` and adapt it into your hook runtime.

Expected behavior:
- a tool call containing a fake secret is blocked
- a normal read/search call is allowed
- a destructive exec pattern is blocked or escalated

## 5. Heartbeat loop works

Set a tiny `HEARTBEAT.md`:

```markdown
# HEARTBEAT.md
- If nothing needs attention, reply HEARTBEAT_OK
```

Trigger your heartbeat mechanism.

Expected:
- no extra chatter
- exact `HEARTBEAT_OK` when nothing is due

## 6. Cron model split is intentional

Check your config / cron definitions:
- heavy review jobs → `gpt-5.4` + `medium`
- routine checks → `spark` only if positively live-routable, else `gpt-5.3-codex`, with `low`
- mechanical loops → `spark` only if positively live-routable, else `gpt-5.3-codex`, with `disabled`

Expected:
- no accidental expensive model on high-frequency jobs
- no stale old-provider model strings in active config
- no use of Spark based only on weak signals like generic model-list presence

## 7. Sub-agent verification loop exists

Spawn one sub-agent for a bounded task, then verify output manually:
- inspect files changed
- run tests
- check diff

Expected:
- no "trust the agent blindly" behavior

## 8. Protected-file integrity baseline exists

```bash
reference/scripts/integrity-check init
reference/scripts/integrity-check check
```

Expected:
- a baseline file is created
- later checks report `ok` until a protected file changes unexpectedly

## 9. Brownfield verification path

If you are adopting the playbook into an already-active workspace, run the focused verifier too:

```bash
reference/scripts/verify-brownfield
```

It checks brownfield-specific assumptions including:
- validation inside a deliberately dirty repo
- wrapper-mode task integration behavior
- archive-first conventions
- selective memory backfill that prefers daily-note signal over noisy exports

## 10. Full local rollout verifier

```bash
reference/scripts/verify-local
```

Expected:
- integrity check passes
- memory readiness passes
- generic verify passes
- brownfield verify passes

## 11. Codex runtime validation

If you are running a Codex-first setup, stop treating model config as sufficient proof.

Check that your local status/health tooling can answer all of these:
- which runtime path is actually active
- which fallback path is actually active
- whether the Codex auth profile is complete
- whether any provider-specific runtime state is healthy
- whether the intended app-server approval policy is actually present

Practical examples:

```bash
status-report
status-report --json
grep -n "approvalPolicy" ~/.openclaw/openclaw.json
```

If you maintain a dedicated runtime health script, run that too.

Expected:
- the reported runtime path matches the path you think is live
- approval policy matches your documented intent
- bridge/auth state is healthy enough that restarts will not immediately regress

## 12. Post-update runtime verification

Package updates are not the finish line. For live systems, they are a drift risk.

After an OpenClaw update or local runtime patch cycle, verify:
- the intended runtime/fallback still holds
- local bundle/runtime fixes were reapplied if your environment depends on them
- the embedded bridge/home still has complete token data
- your status/health surface still reports the Codex path correctly

Expected:
- no silent regression from "works in config" to "broken at runtime"
- no approval or auth surprises caused by overwritten runtime state

## CI

GitHub Actions workflow: `.github/workflows/verify.yml`

It runs on `push` and `pull_request` and checks:
- `bash -n setup.sh`
- `python3 -m py_compile` on the reference Python scripts
- `reference/scripts/verify`
- `reference/scripts/verify-brownfield`

The bundled CI stays intentionally small. Your real workspace can and should add stricter local verifiers around integrity, memory readiness, and deployment-specific checks.

## Optional: Run the bundled verifier stack

```bash
reference/scripts/integrity-check init
reference/scripts/integrity-check check
reference/scripts/verify-memory-readiness
reference/scripts/verify
reference/scripts/verify-brownfield
reference/scripts/verify-local
```

`integrity-check` covers protected-file drift.

`verify-memory-readiness` covers minimum memory-pipeline usability.

`verify` checks script syntax, task flow, task idempotency, sprint/delete contract, and duplicate-safe memory extraction.

`verify-brownfield` adds dirty-repo, wrapper-mode, archive-first, and selective-backfill checks.

`verify-local` runs the recommended live-workspace stack in one pass.

## Exit Criteria

You are ready to build on the playbook when:
- protected files have an integrity baseline
- memory is writable and searchable
- tasks are visible in SQLite
- heartbeat works
- one hook can block unsafe actions
- cron models/thinking are intentional
- Codex runtime health is verifiable, not assumed from config alone
- sub-agent output is verified, not trusted
- brownfield assumptions are checked with repeatable scripts, not conversational confidence
