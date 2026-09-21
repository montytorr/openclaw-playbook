# Maintaining This Playbook

This repository is a playbook, not a second source of truth for a live OpenClaw
installation. The most damaging documentation bugs are plausible commands that
worked months ago.

## Authority order

When sources disagree, use this order:

1. The running installation and its validated CLI/config help.
2. The installation's own `AGENTS.md`, `TOOLS.md`, project files, and skills.
3. Official OpenClaw documentation for the installed release.
4. This playbook's patterns and reference implementations.

The playbook must never override runtime evidence. A green-looking config example
does not prove that a process, route, model, auth profile, or cron is live.

## Curation pass

Run this pass whenever OpenClaw, the task system, a provider, or the host topology
changes:

```bash
# Use the installation's help if a command differs.
openclaw --help
openclaw config validate
openclaw memory status --deep
git grep -n -i 'task start\|task update\|scripts/task\|linear\|memorySearch\|agents.*list\|openclaw gateway restart\|gpt-5\.5\|gpt-5\.5-mini'
./reference/scripts/verify
```

Then replace version-pinned claims with verified placeholders, remove dead commands
from the main path, mark untested material as illustrative, and update templates and
their corresponding chapters together.

## Task authority contract

The playbook requires one authoritative task system per deployment. Cairn is the
reference workflow for the current reference environment:

```bash
cairn check "subject"
cairn add "Title" --project <PROJECT> --type docs --priority medium
cairn claim <REF>
cairn note <REF> "finding" --kind finding
cairn checkpoint <REF> --summary "current state and next action"
cairn done <REF> --resolution "verified result" --kind fixed
```

The bundled SQLite `reference/scripts/task` is retained only as an educational
legacy scaffold. It is not the recommended production authority and must not be
installed alongside an existing task system without an explicit adapter plan.

## Long-running work

Progress messages do not own work. Before announcing a long job, attach it to a
durable worker/session with an adequate timeout and a checkpoint. A terminal Discord
delivery can end the foreground run in some deployments; send progress only after
detached ownership exists. Reconnects, compaction, and UI status are not proof that
work is still executing.

## Protected credentials

Never put credentials in examples, commands, URLs, logs, or chat. Use the host's
masked secret store and pass only opaque references to supported config fields. If a
protected provider call fails, verify it through the host-bound helper and report the
HTTP result without exposing the token. A CLI format error is not proof that the
stored credential is invalid.

## Release checklist

- [ ] runtime-sensitive claims are dated or provider-neutral
- [ ] the example config validates against the installed OpenClaw schema
- [ ] no dead task CLI is in the main path
- [ ] templates and chapters agree
- [ ] setup is idempotent and does not overwrite user files
- [ ] reference checks pass
- [ ] links and shell snippets were inspected
- [ ] `VERSION` and `CHANGELOG.md` were updated
- [ ] the change was committed and pushed
- [ ] a version tag was pushed and a GitHub release was published from the matching changelog section
- [ ] the GitHub repository description still matches the current scope
