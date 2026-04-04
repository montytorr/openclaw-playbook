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
- **System documentation** — detailed descriptions of every operational pattern: hooks, crons, task tracking, security gates, dashboards, and more
- **Memory architecture** — the hybrid markdown + SQLite observation model that gives the agent real continuity
- **Interface specifications** — enough detail to build compatible tools without copying our code

## What You Don't Get

- **Actual implementation code** — we describe patterns and interfaces; you build your own. This is intentional: the playbook focuses on transferable patterns, while your concrete implementations should match your threat model and operating environment.
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

# Start reading
# The playbook is ordered — read chapters 01 through 16 sequentially
```

## Structure

```
openclaw-playbook/
├── README.md              ← You are here
├── LICENSE                ← MIT
├── setup.sh               ← Interactive workspace scaffolding
├── playbook/              ← The main documentation (read in order)
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
└── schemas/               ← Interface specifications
    ├── task-cli.md        ← Task CLI full interface spec
    ├── memory-conventions.md ← Memory file formats & conventions
    └── project-template.md ← Project file format specification
```

## Lean Starting Path

If you don't want the full stack on day one, start with these four things:

1. daily notes in `memory/YYYY-MM-DD.md`
2. a minimal `task` tracker
3. a small `HEARTBEAT.md`
4. one security hook guarding dangerous tool calls

That gives you continuity, visibility, a timing loop, and a perimeter. Add the rest after that works.

## How to Use This

1. **Run `setup.sh`** — creates your workspace directory structure and copies templates
2. **Read the playbook in order** — each chapter builds on the previous ones
3. **Customize templates** — the files in `templates/` are starting points; make them yours
4. **Build your tools** — use the schemas and interface specs to build compatible scripts
5. **Iterate** — your agent's infrastructure will evolve. That's the point.

## Philosophy

This playbook is opinionated. The core beliefs:

- **Agents need identity, not just instructions.** A SOUL.md that defines personality prevents corporate bot syndrome and makes your agent genuinely useful to interact with.
- **Memory is infrastructure.** Without a proper memory system, every session starts from zero. The real breakthrough is the hybrid model: markdown for narrative continuity, SQLite for observation storage and retrieval, and `MEMORY.md` as the operator-facing digest.
- **Track everything.** Rule Zero exists because autonomous agents that don't track their work become black boxes. If it happened, it should be logged.
- **Security is non-negotiable.** The moment you give an agent access to your email, git, and infrastructure, you need defense in depth. Not paranoia — engineering.
- **Build your own tools.** Copying someone else's hooks and scripts gives you their security assumptions without their context. Understand the pattern, then implement it yourself.
- **Private-first beats public-by-default.** If an admin surface can live behind Tailscale or another private network, keep it there.

## Contributing

This is an educational resource. If you've built operational patterns that others would benefit from, open a PR. We're particularly interested in:

- New hook patterns we haven't documented
- Alternative approaches to problems we've solved differently
- Corrections or clarifications

## License

MIT — see [LICENSE](LICENSE).

---

*Built from real operational experience. No theoretical frameworks — just patterns that survived production.*
