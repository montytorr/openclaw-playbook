# Chapter 10: Clones

Once your agent is running well on one server, you'll want to replicate the pattern. Clones are independent OpenClaw instances — each on its own server, with its own identity, workspace, and configuration — that share operational patterns but serve different purposes.

## Concept

Think of clones like franchise locations: same operating manual, different addresses, different staff, different local customers. Each clone:

- Runs its own OpenClaw gateway
- Has its own workspace directory
- Has its own SOUL.md, IDENTITY.md, USER.md
- Can share skills and hooks with other clones
- Operates independently (no real-time coordination required)

## Why Clones

| Scenario | Why a Clone |
|----------|------------|
| Different project focus | One clone for trading, one for a SaaS product |
| Different servers | Geographic distribution, isolation |
| Different access levels | One clone has production access, one doesn't |
| Different identities | Each clone has its own personality for its domain |
| Resource isolation | Heavy operations don't impact the main agent |

## Identity Separation

Each clone gets its own identity files:

```
Clone A (main server):
├── IDENTITY.md     → "Alpha" — general-purpose operator
├── SOUL.md         → Dry wit, technical, infrastructure-focused
└── USER.md         → Full user profile

Clone B (project server):
├── IDENTITY.md     → "Beta" — project-specific builder
├── SOUL.md         → Focused, sprint-oriented, product-minded
└── USER.md         → Subset of user profile relevant to this project
```

The key rule: **clones are autonomous contexts.** Don't assume files, services, or state on one host apply to another unless explicitly synchronized.

## The Foundry System

Foundry is a packaging and deployment tool for sharing skills across clones. It answers the question: "How do I keep my hooks and scripts consistent across multiple instances without manual copying?"

### foundry.toml

Lives at the workspace root, defines the project and its targets:

```toml
[project]
name = "my-skill-pack"
version = "1.0.0"
description = "Shared skills and hooks for my agent fleet"

[targets.alpha]
type = "local"
workspace = "/root/clawd"

[targets.beta]
type = "remote"
host = "192.168.1.100"
user = "root"
workspace = "/root/clawd"
ssh_key = "~/.ssh/id_ed25519"

[targets.gamma]
type = "remote"
host = "10.0.0.50"
user = "root"
workspace = "/root/clawd"
ssh_key = "~/.ssh/id_ed25519"
```

### Per-Skill Packaging

Each skill directory gets a `foundry-package.json`:

```json
{
  "name": "the-wall",
  "version": "1.2.0",
  "type": "hook",
  "description": "Before-tool-call security gate",
  "files": [
    "index.ts",
    "config/autonomy-tiers.json"
  ],
  "targets": ["alpha", "beta", "gamma"]
}
```

The `targets` field controls which clones receive this skill. Some skills are universal (security hooks); others are instance-specific (trading bot goes to the trading clone only).

### Workflow

```bash
# 1. Validate all packages
foundry validate

# 2. Generate catalog (index of all packages)
foundry catalog generate

# 3. Build distribution package
foundry build

# 4. Publish to a specific target
foundry publish --target beta

# 5. Or publish to all targets
foundry publish --all
```

The publish step:
1. Connects to the target (local copy or SSH)
2. Copies packaged files to the target workspace
3. Verifies integrity after copy
4. Optionally triggers a gateway restart on the target

### What to Share, What to Keep Unique

| Component | Share? | Why |
|-----------|--------|-----|
| Security hooks (the-wall, agent-firewall) | ✅ Yes | Consistent security baseline across all clones |
| Automation hooks (auto-git-commit) | ✅ Yes | Same operational patterns everywhere |
| Observability hooks (llm-observer) | ✅ Yes | Unified cost tracking |
| SOUL.md, IDENTITY.md | ❌ No | Each clone has its own personality |
| AGENTS.md | ⚠️ Partial | Share the framework, customize per-clone sections |
| config/autonomy-tiers.json | ⚠️ Partial | Base tiers shared, clone-specific additions |
| Domain-specific skills | ❌ No | Trading skill only goes to trading clone |
| Scripts | ✅ Mostly | Utility scripts are universal |

## Config Sync Considerations

When managing multiple clones:

1. **Version your configs** — git track `openclaw.json` (without secrets) on each clone
2. **Use a shared base** — common config elements in a template, per-clone overrides
3. **Secrets stay local** — `.env` is never synced between clones
4. **Test on one clone first** — deploy config changes to a non-critical clone, verify, then propagate
5. **Document differences** — maintain a table of what's different between clones

## What to Build

- [ ] Set up your first clone on a second server
- [ ] Create unique IDENTITY.md and SOUL.md for the clone
- [ ] Initialize `foundry.toml` with your target definitions
- [ ] Add `foundry-package.json` to skills you want to share
- [ ] Test the validate → build → publish workflow
- [ ] Set up SSH key access between servers for remote publishing
- [ ] Document which skills are shared and which are clone-specific
- [ ] Create a config diff document comparing clone configurations

---

*Previous: [Chapter 9 — Config](09-config.md) | Next: [Chapter 11 — Nodes](11-nodes.md)*
