# Chapter 3: Task Management

Rule Zero is a coordination contract, not a particular database schema: check the
authoritative task system before work, create or claim durable work, record findings
as they happen, and close with a resolution.

## One authority per deployment

Do not run a private SQLite task database beside a shared task system. That creates
split-brain status, duplicate work, and misleading dashboards. If an existing system
is present, write an adapter or use it directly. Cairn is the reference workflow:

```bash
cairn check "subject or failure"
cairn add "Curate documentation" --project <PROJECT> --type docs --priority medium
cairn claim <REF>
cairn note <REF> "what was tried" --kind attempt
cairn checkpoint <REF> --summary "current state and next action"
cairn done <REF> --resolution "what changed and why" --kind fixed
```

Use `cairn show`, `cairn log`, and `cairn list` for inspection. Use the actual
project key and categories defined by the deployment; never copy another operator's
keys as if they were universal.

## When to create work

Create a durable task for bugs, features, investigations, deployments, migrations,
config changes, and work likely to outlive the current turn. Routine telemetry and
trivial conversational acknowledgements do not need tasks.

Before spawning a sub-agent or detached worker, create or claim the parent task and
record the ownership/checkpoint. A child may use a linked task or notes, but must not
become the only record of why the work exists.

## Status and ownership

The task system's status model is authoritative. At minimum, distinguish planned,
active, blocked, and done (or map those concepts through an adapter). A task marked
done without a resolution is not evidence of completion. A dashboard card, session
row, or progress message is not a worker.

For long jobs, record:

- durable owner/session and timeout budget
- current checkpoint and next action
- external dependencies and blockers
- verification evidence before closing

## Reconciliation

If work was performed without a task, add it retroactively immediately. Do not create
a second task merely because a UI or monitor shows a stale copy. Search first, then
link, update, or supersede the existing record.

## Educational legacy reference

`reference/scripts/task` and `schemas/task-cli.md` are retained to illustrate how a
tiny local adapter can work. They are not the production recommendation. New
deployments should use their existing authority (Cairn in the current reference
environment) and document the adapter boundary if they need compatibility.

## Verification

Prove the real authority, not just a mock command:

1. Search for an existing task before creating one.
2. Create or claim a disposable verification task.
3. Record a note and checkpoint.
4. Close it with an explicit resolution.
5. Confirm it is retrievable after a new shell/session.

See [Maintaining This Playbook](../docs/maintenance-and-drift.md) and
[Chapter 13 — Sub-agents](13-sub-agents.md).

---

*Previous: [Chapter 2 — Memory System](02-memory-system.md) | Next: [Chapter 4 — Hooks](04-hooks.md)*
