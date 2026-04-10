# Reference Implementations

These are **minimal starter artifacts**, not production-ready drop-ins.

**Repeat that to yourself before copying them into production.** They are educational scaffolds meant to prove the loop is executable.

Use them to reduce blank-page friction:

By default they assume `~/clawd` as the workspace root. Override with:

```bash
WORKSPACE_ROOT=/path/to/workspace <script>
```

- `scripts/task` — tiny SQLite-backed task CLI (with explicit exit code `2` for not-found on `show`, `update`, `set-input`, and `delete`)
- `scripts/mem-extract` — tiny memory extractor from daily notes into SQLite
- `scripts/mem-search` — FTS-backed search over observations
- `scripts/integrity-check` — tiny protected-file integrity baseline checker (`init`, `check`, `show`)
- `scripts/verify-memory-readiness` — validates that the memory pipeline is minimally usable
- `scripts/verify` — smoke-test script for the starter references
- `scripts/verify-brownfield` — brownfield-specific verification for dirty repos, wrappers, archives, and selective backfill assumptions
- `scripts/verify-local` — recommended live-workspace verifier stack: integrity, memory readiness, generic verify, then brownfield verify
- `adapters/task-wrapper.example.py` — example mapping layer that wraps an existing task CLI/API into the playbook task contract
- `hooks/the-wall.example.ts` — secret scan + destructive-exec gate skeleton
- `hooks/task-enforcer.example.ts` — tiny reminder-style enforcement skeleton

## Philosophy

These references exist to prove the patterns are executable.
They are intentionally small, incomplete, and easy to replace.

The repo also includes `.github/workflows/verify.yml`, which runs the bundled reference checks on pushes and pull requests.

Do not confuse:
- **reference implementation** = educational scaffold
- **production implementation** = hardened for your environment
