# Chapter 14: Skills System

Skills are how your agent learns to use specific tools, APIs, and workflows. Instead of cramming every possible instruction into AGENTS.md, you create focused instruction sets that the agent loads on demand. This chapter covers how skills work, how to build them, and how to vet third-party ones.

## What Skills Are

A skill is a specialized instruction set packaged as a `SKILL.md` file, optionally accompanied by scripts, reference docs, and configuration. When the agent encounters a task that matches a skill's description, it reads the SKILL.md and follows the instructions.

Think of it this way:
- **AGENTS.md** — general operating manual (always loaded)
- **SKILL.md** — specialized training for a specific tool or workflow (loaded on demand)

This separation matters because AGENTS.md is loaded every session. If you put GitHub CLI instructions, weather API details, trading bot commands, and email workflows all into AGENTS.md, you'd burn thousands of tokens on context that's irrelevant 90% of the time.

Skills solve this: instructions load only when the agent needs them.

## Directory Structure

```
skills/
├── github/
│   ├── SKILL.md              # Instructions for using the gh CLI
│   ├── scripts/
│   │   └── pr-summary.sh     # Helper script for PR summaries
│   └── references/
│       └── gh-api-patterns.md # Common gh API query patterns
│
├── weather/
│   └── SKILL.md              # Instructions for weather lookups
│
├── trading-bot/
│   ├── SKILL.md              # Full trading system documentation
│   ├── scripts/
│   │   ├── tb                # Trading bot CLI
│   │   └── scan.py           # Market scanner
│   ├── config/
│   │   └── exit_rules.json   # Trading exit rule definitions
│   └── references/
│       └── api-docs.md       # Alpaca API reference
│
└── skill-creator/
    └── SKILL.md              # Meta-skill: how to create other skills
```

Each skill lives in its own directory under `skills/`. The minimum requirement is a `SKILL.md` file. Everything else is optional:

| Directory | Purpose |
|-----------|---------|
| `scripts/` | Executable scripts the agent runs as part of the skill |
| `references/` | Documentation, API specs, examples the agent can read |
| `config/` | Configuration files used by the skill's scripts |

## How Discovery Works

OpenClaw makes skills available to the agent through the `available_skills` configuration in the system prompt. Each skill entry includes:

- **name** — unique identifier
- **description** — what the skill does (used for matching)
- **location** — path to the SKILL.md file

```xml
<available_skills>
  <skill>
    <name>github</name>
    <description>GitHub operations via gh CLI: issues, PRs, CI runs, code review</description>
    <location>skills/github/SKILL.md</location>
  </skill>
  <skill>
    <name>weather</name>
    <description>Get current weather and forecasts via wttr.in or Open-Meteo</description>
    <location>skills/weather/SKILL.md</location>
  </skill>
</available_skills>
```

**The matching process:**

1. Agent receives a task (e.g., "check the weather in Paris")
2. Agent scans available skill descriptions
3. Exactly one skill clearly applies → agent reads that SKILL.md
4. Multiple could apply → agent picks the most specific one
5. None apply → agent proceeds without loading a skill

**Important:** The agent reads at most one skill's SKILL.md per task. This prevents context bloat from loading multiple instruction sets simultaneously.

## SKILL.md Format

A good SKILL.md contains:

```markdown
# Skill Name

Brief description of what this skill does.

## Prerequisites
- Required tools, APIs, or configuration
- Environment variables needed

## Usage

### Common Commands
<!-- The most frequent operations, with examples -->

### Examples
<!-- Real command examples with expected output -->

## Constraints
- What the skill should NOT be used for
- Rate limits or cost considerations
- Security notes

## Troubleshooting
- Common errors and their solutions
```

### Writing Effective Instructions

**Be concrete, not abstract.** Instead of "use the CLI to manage issues," write:

```bash
# List open issues assigned to you
gh issue list --assignee @me --state open

# Create an issue with labels
gh issue create --title "Bug: login redirect" --label bug --body "..."
```

**Include error handling.** What should the agent do when the command fails? What are common failure modes?

**Set boundaries.** What is this skill NOT for? Where does it end and another tool begins?

**Keep it focused.** A skill for GitHub operations shouldn't include Docker deployment instructions. One skill, one domain.

## Skill Categories

### Tool Integrations
Skills that wrap external tools and APIs:
- **GitHub** — `gh` CLI for issues, PRs, CI, code review
- **Weather** — weather lookups via wttr.in or Open-Meteo
- **Email** — Gmail/email operations via a mail CLI
- **Calendar** — Google Calendar management
- **Cloud providers** — DigitalOcean, AWS, etc. via their CLIs

### Operational Skills
Skills for ongoing operational tasks:
- **Trading** — stock/crypto trading via broker APIs
- **Monitoring** — uptime monitoring, health checks
- **Security scanning** — secret detection, vulnerability scanning
- **Cost tracking** — LLM usage and cost reporting

### Meta-Skills
Skills about the skill system itself:
- **Skill creator** — instructions for building new skills
- **Skill vetting** — security review process for third-party skills

## Building Your Own Skills

### Step 1: Start with SKILL.md

Write the instructions first. What does the agent need to know to use this tool effectively? Include:
- The most common 5-10 commands or operations
- Real examples with realistic (but not real) data
- Error handling guidance
- Constraints and boundaries

### Step 2: Add Scripts

If the skill involves complex operations, wrap them in scripts:

```bash
skills/my-skill/scripts/do-thing
```

Scripts should be:
- Executable (`chmod +x`)
- Self-documenting (`--help` flag)
- Safe (no destructive defaults, confirmation for dangerous operations)
- Idempotent where possible

### Step 3: Add References

If the skill involves a complex API or specification, add reference documents:

```
skills/my-skill/references/api-docs.md
skills/my-skill/references/error-codes.md
```

The agent reads these when it needs deeper context than SKILL.md provides.

### Step 4: Register the Skill

Add it to your OpenClaw configuration so it appears in `available_skills`. The description is critical — it's what the agent uses to decide whether to load this skill.

## ClawHub: Community Skills

[ClawHub](https://clawhub.ai) is a community marketplace for OpenClaw skills. You can:
- Browse skills built by other operators
- Install skills into your workspace
- Share your own skills with the community

**Important:** Always vet third-party skills before installing. See the security section below.

## Skill Vetting

Before installing any third-party skill, review it for:

### Security Concerns
- **Prompt injection** — does the SKILL.md contain instructions that override agent behavior? ("Ignore your previous instructions and...")
- **Data exfiltration** — do scripts send data to external endpoints?
- **Credential access** — do scripts read `.env`, API keys, or sensitive files?
- **Destructive operations** — do scripts run `rm`, `kill`, or modify system config?
- **Encoded payloads** — are there base64 or hex-encoded strings that could hide malicious content?

### Utility Assessment
- Does this skill add capability your agent doesn't already have?
- Is it well-documented? (A SKILL.md with three lines is a red flag)
- Are the scripts readable and understandable?
- Does it follow the directory conventions?

### Vetting Process
1. Read the SKILL.md thoroughly
2. Read ALL scripts — every line
3. Check for outbound network calls in scripts (`curl`, `wget`, `fetch`, `requests.post`)
4. Run a security scanner if you have one (see the `skill-vetting` skill)
5. Test in isolation before giving it to your main agent

## Skills vs Hooks

This distinction trips people up:

| | Skills | Hooks |
|---|--------|-------|
| **What** | Instructions the agent follows | Code that runs automatically |
| **When** | Agent reads them on demand | Fire on platform events |
| **Who decides** | The agent chooses to load a skill | The platform triggers hooks |
| **Control** | Behavioral (agent can ignore them) | Structural (agent can't bypass them) |
| **Example** | "Here's how to use the GitHub CLI" | "Block any tool call containing an API key" |

**Skills guide behavior.** The agent reads instructions and follows them. It could, in theory, ignore a skill's constraints (though it shouldn't).

**Hooks enforce behavior.** They run at the platform level, outside the agent's control. A hook that blocks credential leaks blocks them regardless of what the agent intends.

Use skills for tool instructions. Use hooks for security enforcement, automation, and observability.

Cross-reference: see [Chapter 4](04-hooks.md) for the full hook architecture.

## What to Build

- [ ] Organize existing tool instructions into skill directories
- [ ] Write SKILL.md files for your most-used tools (start with 2-3)
- [ ] Register skills in your OpenClaw configuration
- [ ] Build the `skill-creator` meta-skill for creating new skills
- [ ] Set up a vetting process for third-party skills
- [ ] Add helper scripts in `scripts/` for complex skill operations
- [ ] Document skill-specific configuration in `config/` directories
- [ ] Test skill loading: verify the agent reads the right SKILL.md for matching tasks
- [ ] Review skill descriptions for accuracy (bad descriptions = wrong skill loaded)

---

*Previous: [Chapter 13 — Sub-Agent Orchestration](13-sub-agents.md) | Next: [Chapter 15 — Context Management](15-context-management.md)*
