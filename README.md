# OpenClaw Playbook

An educational playbook for running an autonomous OpenClaw agent. Built from real operational patterns — battle-tested across months of 24/7 autonomous operation.

**Current examples reflect a Codex-first production setup** (`gpt-5.4` + `gpt-5.3-codex-spark`) after the Claude OAuth path stopped being a reliable OpenClaw runtime option.

## Who This Is For

Experienced developers who:
- Have OpenClaw installed and running
- Know Linux, Docker, and basic sysadmin
- Want to build a *real* autonomous agent, not just a chatbot
- Are ready to invest time in infrastructure that compounds

## What You Get

- **Workspace structure** — a proven directory layout for agent memory, projects, scripts, and security
- **Identity templates** — ready-to-customize files that give your agent personality, memory, and behavioral guardrails
- **System documentation** — detailed descriptions of every operational pattern: hooks, crons, task tracking, security gates, dashboards, webhook queues, A2A reactors, and more
- **Memory architecture** — the hybrid markdown + SQLite observation model that gives the agent real continuity
- **Interface specifications** — enough detail to build compatible tools without copying our code
- **Reference implementations** — tiny runnable scripts and hook skeletons so you don't start from a blank page
- **Validation docs** — smoke tests for proving the loop actually works
- **Smoke-test script** — a bundled verification pass for the starter references
- **Brownfield extras** — adapter scaffolds, migration case study, and verifier for active-workspace adoption
- **GitHub Actions CI** — a minimal verify workflow for push + pull_request

## What You Don't Get

- **Full production implementation code** — this is not a copy of our live runtime. The included references are intentionally minimal and educational, not hardened drop-ins.
- **API keys or secrets** — all credentials use `<YOUR_KEY_HERE>` placeholders
- **Our specific configurations** — the playbook is generic. Adapt everything to your setup.

## Safety Note

This repository documents **power-user patterns**. Some examples involve reverse proxies, public webhooks, browser automation, SSH tunnels, Docker socket access, and agent control surfaces.

Treat everything here as **infrastructure guidance for experienced operators**, not copy-paste defaults.

**Strong recommendations:**
- Prefer **private access** (Tailscale, LAN, VPN) for admin surfaces
- Do **not** expose your agent gateway publicly unless you understand the implications
- Never publish real tokens, hostnames, node IDs, internal routes, or production config files
- Mark dangerous snippets in your own docs as advanced / optional, not baseline defaults

## Quick Start

```bash
# Clone this repo
git clone https://github.com/montytorr/openclaw-playbook.git
cd openclaw-playbook

# Run the setup script
chmod +x setup.sh
./setup.sh

# Or bootstrap headlessly / in CI
./setup.sh --workspace /tmp/clawd --non-interactive --skip-commit

# Start reading
# The playbook is ordered — read chapters 00 through 16 sequentially
```

## Structure

```
openclaw-playbook/
├── README.md              ← You are here
├── LICENSE                ← MIT
├── setup.sh               ← Workspace scaffolding (interactive by default, automation-friendly flags available)
├── playbook/              ← The main documentation (read in order)
│   ├── 00-brownfield-adoption.md ← Adopting the playbook into active environments
│   ├── 01-foundations.md  ← Workspace structure & identity files
│   ├── 02-memory-system.md ← Daily notes, MEMORY.md, claude-mem
│   ├── 03-task-management.md ← SQLite task CLI & Rule Zero
│   ├── 04-hooks.md        ← Hook architecture & patterns
│   ├── 05-security.md     ← Security model & threat defense
│   ├── 06-cron-patterns.md ← Scheduling: heartbeats vs crons
│   ├── 07-scripts-toolkit.md ← Utility scripts & patterns
│   ├── 08-dashboard.md    ← Centralized visibility & monitoring
│   ├── 09-config.md       ← openclaw.json & environment setup
│   ├── 10-clones.md       ← Multi-instance deployments
│   ├── 11-nodes.md        ← Companion devices & browser profiles
│   ├── 12-a2a-comms.md   ← Agent-to-agent communication
│   ├── 13-sub-agents.md  ← Sub-agent orchestration & parallel work
│   ├── 14-skills.md      ← Skills system & on-demand instructions
│   ├── 15-context-management.md ← Context windows & compaction resilience
│   └── 16-infrastructure.md  ← Traefik, Docker networking, Tailscale, DNS
├── templates/             ← Ready-to-use workspace files
│   ├── AGENTS.md          ← Main instruction set template
│   ├── SOUL.md            ← Personality & behavioral guardrails
│   ├── IDENTITY.md        ← Agent identity card
│   ├── USER.md            ← Human operator profile
│   ├── HEARTBEAT.md       ← Heartbeat poll configuration
│   ├── TOOLS.md           ← Local tool & infrastructure notes
│   ├── SECURITY.md        ← Security rules & protocols
│   └── openclaw.example.json ← Configuration skeleton
├── reference/             ← Minimal runnable starter artifacts
│   ├── README.md          ← How to use the references
│   ├── adapters/          ← Example wrapper-mode integration artifacts
│   ├── hooks/             ← Hook skeleton examples
│   └── scripts/           ← Tiny task/memory reference scripts
├── docs/                  ← Condensed onboarding & validation
│   ├── case-studies/
│   │   └── brownfield-migration-example.md ← Short active-workspace adoption example
│   ├── one-pager.md       ← Fast-start summary
│   └── validation.md      ← Smoke tests for the operating loop
└── schemas/               ← Interface specifications
    ├── task-cli.md        ← Task CLI full interface spec
    ├── memory-conventions.md ← Memory file formats & conventions
    ├── brownfield-adoption-template.md ← Baseline, mapping, and validation template
    └── project-template.md ← Project file format specification
```

## Lean Starting Path

If you don't want the full stack on day one, start with these four things:

1. daily notes in `memory/YYYY-MM-DD.md`
2. a minimal `task` tracker
3. a small `HEARTBEAT.md`
4. one security hook guarding dangerous tool calls

That gives you continuity, visibility, a timing loop, and a perimeter. Add the rest after that works.

## Two High-Leverage Patterns Worth Stealing

### 1. The Wall should start narrow, not tyrannical

In brownfield setups, `the-wall` should hard-block only high-confidence dangerous cases everywhere:
- credential leaks
- destructive commands
- obviously auth-bearing outbound requests

Then apply stricter scrutiny first around:
- A2A surfaces
- webhook/reactor paths
- sub-agent delegation
- external publish/send paths

That's the sane order. Turning it into a universal blocker for every harmless workflow on day one is how people stop trusting the system.

### 2. A2A works best with a receiver + queue + reactor

The reliable A2A pattern is:

```text
webhook receiver -> durable queue -> a2a-reactor -> side effects
```

Meaning:
- the receiver verifies HMAC and persists events fast
- the queue absorbs retries and survives restarts
- the reactor decides what to do: create tasks, notify humans, wake the agent, or stay quiet
- a cron fallback can re-run the reactor if the immediate wake path fails

If you remember one thing from the collaboration stack, remember that. Don't bury heavy logic in the webhook handler.

## How to Use This

1. **Run `setup.sh`** — creates your workspace directory structure and copies templates
   - For automation/headless bootstrap, use `--non-interactive`
   - Use `--workspace PATH` to avoid the prompt entirely
   - Use `--skip-commit` if you want git initialized without creating the first commit yet
2. **Read `docs/one-pager.md`** — get the operating loop in your head fast
3. **If you're adopting into an existing environment, start with `playbook/00-brownfield-adoption.md`** — inventory reality before changing anything
4. **Read the playbook in order** — each chapter builds on the previous ones
4. **Customize templates** — the files in `templates/` are starting points; make them yours
5. **Use `reference/` for starter implementations** — task CLI, memory extractor/search, hook skeletons
6. **Run `docs/validation.md` or `reference/scripts/verify`** — prove the starter loop works
7. **If you're in a live workspace, also run `reference/scripts/verify-brownfield`** — validate dirty-repo, wrapper, archive, and memory-backfill assumptions
8. **Iterate** — your agent's infrastructure will evolve. That's the point.

## Philosophy

This playbook is opinionated. The core beliefs:

- **Agents need identity, not just instructions.** A SOUL.md that defines personality prevents corporate bot syndrome and makes your agent genuinely useful to interact with.
- **Memory is infrastructure.** Without a proper memory system, every session starts from zero. The real breakthrough is the hybrid model: markdown for narrative continuity, SQLite for observation storage and retrieval, and `MEMORY.md` as the operator-facing digest.
- **Track everything.** Rule Zero exists because autonomous agents that don't track their work become black boxes. If it happened, it should be logged.
- **Brownfield beats fantasy.** Most real adoptions happen in already-active environments. Optimize for reversibility, wrappers, archives, and validation inside a dirty repo — not imaginary clean-room migrations.
- **Security is non-negotiable.** The moment you give an agent access to your email, git, and infrastructure, you need defense in depth. Not paranoia — engineering.
- **Build your own tools.** Copying someone else's hooks and scripts gives you their security assumptions without their context. Understand the pattern, then implement it yourself.
- **Private-first beats public-by-default.** If an admin surface can live behind Tailscale or another private network, keep it there.

## Verification

Local smoke tests:

```bash
reference/scripts/verify
reference/scripts/verify-brownfield
```

CI runs the same checks on every push and pull request via `.github/workflows/verify.yml`:
- `bash -n setup.sh`
- `python3 -m py_compile` for the reference Python scripts
- `reference/scripts/verify`
- `reference/scripts/verify-brownfield`

## Contributing

This is an educational resource. If you've built operational patterns that others would benefit from, open a PR. We're particularly interested in:

- New hook patterns we haven't documented
- Alternative approaches to problems we've solved differently
- Corrections or clarifications

## License

MIT — see [LICENSE](LICENSE).

---

*Built from real operational experience. No theoretical frameworks — just patterns that survived production.*
