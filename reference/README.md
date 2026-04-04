# Reference Implementations

These are **minimal starter artifacts**, not production-ready drop-ins.

Use them to reduce blank-page friction:

By default they assume `~/clawd` as the workspace root. Override with:

```bash
WORKSPACE_ROOT=/path/to/workspace <script>
```

- `scripts/task` — tiny SQLite-backed task CLI
- `scripts/mem-extract` — tiny memory extractor from daily notes into SQLite
- `scripts/mem-search` — FTS-backed search over observations
- `hooks/the-wall.example.ts` — secret scan + destructive-exec gate skeleton
- `hooks/task-enforcer.example.ts` — tiny reminder-style enforcement skeleton

## Philosophy

These references exist to prove the patterns are executable.
They are intentionally small, incomplete, and easy to replace.

Do not confuse:
- **reference implementation** = educational scaffold
- **production implementation** = hardened for your environment
