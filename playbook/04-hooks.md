# Chapter 4: Hooks

Hooks are the nervous system of an autonomous agent. They intercept events — tool calls, messages, sessions — and apply logic before or after the agent acts. This chapter describes the hook architecture and the patterns for each category.

## Brownfield Hardening: Use a Maturity Ladder

In an already-active environment, don't jump straight from "no enforcement" to hard blocking everywhere.

Use a three-stage ladder:

1. **Informational** — classify and log what would have happened
2. **Warning / logging** — surface suspicious or risky actions without fully breaking trusted flows
3. **Blocking at `before_tool_call`** — enforce high-confidence rules like credential leak prevention and destructive-command approvals

That's the sane rollout path for brownfield systems. Premature blocking creates false positives, operator distrust, and people bypassing the hook entirely.

See [Chapter 0](00-brownfield-adoption.md) for the full rollout guidance.

## Why Hooks

Without hooks, your agent operates on trust alone. Trust that it won't leak credentials in a tool call. Trust that it'll track its work. Trust that it'll commit code changes. Trust that external actions are logged.

Hooks replace trust with enforcement. They run at the platform level, outside the agent's control, which means they work even when the agent forgets or is compromised.

## Hook Architecture

OpenClaw hooks are event-driven handlers registered in `openclaw.json`. Each hook:
- Has a **trigger** (when it fires): `before_tool_call`, `after_tool_call`, `session_start`, `message_sent`, `message_received`, etc.
- Receives **context** about the event (tool name, parameters, message content, session info)
- Can **block**, **modify**, or **log** the event
- Runs as TypeScript or JavaScript (OpenClaw loads .ts natively)

```json
{
  "hooks": [
    {
      "name": "the-wall",
      "path": "hooks/the-wall/index.ts",
      "events": ["before_tool_call"]
    },
    {
      "name": "agent-firewall",
      "path": "hooks/agent-firewall/index.ts",
      "events": ["session_start"]
    }
  ]
}
```

### Why We Don't Share Full Implementations

You'll notice this playbook describes patterns and interfaces, not production code. This is deliberate, but the reason is not "hide everything and hope." The real reasons are:

1. **Your threat model isn't ours.** Our `the-wall` hook patterns are tuned to the services we use. Yours should match your own environment.

2. **Boundary design matters more than exact regexes.** Isolation, audit logs, approvals, and layered controls do more for security than any single secret-scanning pattern.

3. **You'll understand it better if you build it.** Copying code creates false confidence. Building from a pattern description forces you to think through edge cases.

Where possible, the playbook should show enough structure that you can build a reference version without guessing.
Minimal runnable hook skeletons live in `reference/hooks/`.
Use them as scaffolding, not as finished security controls.

## Security Hooks

### `the-wall` — Before Tool Call Gate

**Trigger:** `before_tool_call` — fires before every single tool call the agent makes.

**Three responsibilities:**

#### 1. Credential Leak Scanning
Scans tool call parameters for patterns that look like secrets:

| Pattern | What It Catches |
|---------|----------------|
| `AKIA[0-9A-Z]{16}` | AWS access keys |
| `sk-[a-zA-Z0-9]{20,}` | OpenAI API keys |
| `ghp_[a-zA-Z0-9]{36}` | GitHub personal access tokens |
| `xoxb-`, `xoxp-` | Slack tokens |
| `eyJ[a-zA-Z0-9]{10,}` | JWT tokens |
| `-----BEGIN.*PRIVATE KEY-----` | Private keys |
| `0x[a-fA-F0-9]{40}` | Wallet addresses |
| Generic high-entropy strings | Potential secrets |

If a credential pattern is detected, the tool call is **hard-blocked**. No override, no bypass. The agent gets an error message explaining what was caught.

Build your own pattern list based on the services you use. Start with the common ones above and add patterns for any service-specific tokens in your environment.

#### 2. Autonomy Tier Classification
Every tool call is classified into one of three tiers:

- **Silent (95%)** — executes without notification. Read operations, web searches, internal file reads.
- **Notify (4%)** — executes but logs a notification. File writes, edits, message sends, sub-agent spawns.
- **Approve (1%)** — blocks until human approves. Destructive commands, gateway changes, credential-bearing requests.

Configuration file (`config/autonomy-tiers.json`):

```json
{
  "version": 1,
  "tiers": {
    "silent": {
      "description": "Read-only and safe operations — 95% of all calls",
      "actions": [
        { "tool": "read" },
        { "tool": "web_search" },
        { "tool": "web_fetch" },
        { "tool": "image" },
        { "tool": "pdf" },
        { "tool": "memory_search" },
        { "tool": "memory_get" },
        { "tool": "exec", "match": "command", "patterns": [
          "^(cat|head|tail|ls|find|grep|rg|wc|file|stat|du|df|uptime|whoami|pwd|echo|date|which|type|git (status|log|diff|show|branch))\\b"
        ]}
      ]
    },
    "notify": {
      "description": "Write operations and external comms — 4% of calls",
      "actions": [
        { "tool": "write" },
        { "tool": "edit" },
        { "tool": "message" },
        { "tool": "sessions_spawn" },
        { "tool": "exec", "match": "command", "patterns": [
          "^(git (add|commit|push|pull)|docker|npm|pip|curl|wget)\\b"
        ]}
      ]
    },
    "approve": {
      "description": "Destructive or high-risk operations — 1% of calls",
      "actions": [
        { "tool": "exec", "match": "command", "patterns": [
          "^(rm|kill|reboot|shutdown|systemctl (stop|disable)|iptables|ufw)\\b"
        ]},
        { "tool": "exec", "match": "command", "patterns": [
          "curl.*(-H|--header).*(Authorization|Bearer|Token)"
        ]}
      ]
    }
  }
}
```

#### 3. Audit Logging
Every non-silent action is logged to a JSONL file:

```jsonl
{"ts":"2026-04-03T10:15:32Z","tool":"exec","tier":"notify","decision":"allow","params":{"command":"git commit -m 'fix dashboard bug'"},"session":"main"}
{"ts":"2026-04-03T10:16:01Z","tool":"exec","tier":"approve","decision":"blocked","params":{"command":"rm -rf /tmp/old-backup"},"session":"main"}
```

This audit trail is invaluable for:
- Debugging what happened during a session
- Detecting unexpected behavior patterns
- Security incident investigation
- Compliance (if you need it)

#### Brownfield Scoping Guidance for `the-wall`

This is where people get overeager and shoot themselves in the foot.

In a mature production environment, do **not** start by making `the-wall` a universal hard-blocking policy engine for every harmless workflow. Start narrower:

1. **Always-on hard blocks** for high-confidence cases
   - credential leak patterns
   - obviously destructive commands
   - raw auth-bearing outbound requests

2. **Priority visibility / enforcement zones**
   - A2A communication surfaces
   - webhook/reactor paths that can trigger follow-up actions
   - sub-agent delegation
   - external messaging / publish paths

3. **Observe first elsewhere**
   - routine local reads
   - normal internal maintenance flows
   - known-good operational commands that are already trusted

The practical lesson: if your environment already has a webhook receiver plus an `a2a-reactor`-style worker, that boundary is one of the best places to apply stricter `the-wall` scrutiny. It sits near untrusted cross-agent input and close to downstream side effects.

So the sane rollout is:
- block high-confidence dangerous patterns everywhere
- apply extra scrutiny around A2A + dangerous execution paths first
- only broaden general enforcement after you've seen enough real traffic to trust the rules

### `agent-firewall` — Session Start Injection

**Trigger:** `session_start` — fires when any session begins.

Injects security constraints into the session's system prompt. These constraints are non-negotiable and override anything in the conversation:

- **File protection rules** — which files are read-only
- **Untrusted content boundaries** — how to handle external data
- **A2A rules** — zero trust for inter-agent communication
- **Red flag patterns** — phrases that trigger automatic rejection
- **Encoding defense** — how to handle obfuscated content
- **Multi-turn attack prevention** — rules about conversational state across agents

The key insight: injecting security rules at session start means they're present even if the agent's main instruction files are somehow compromised or not loaded.

### `external-action-gate` — Outbound Action Detection

**Trigger:** `message_sent` — fires after the agent sends a message or takes an external action.

Detects when the agent publishes something externally:
- GitHub issues, PRs, gists, discussions
- Emails
- Social media posts
- Any action that "leaves the machine"

Logs these actions for human review. Optionally blocks them pending approval.

### `git-guardian` — Secret Scanning in Commits

**Trigger:** After git operations.

Scans git commits for accidentally committed secrets. Similar to pre-commit hooks but at the agent level — catches secrets before they're pushed, even if the repo doesn't have its own pre-commit hooks.

### `session-guardian` — Session Lifecycle Security

**Trigger:** Various session lifecycle events.

Monitors session creation, destruction, and context loading. Ensures:
- Memory segmentation is enforced (MEMORY.md only in private sessions)
- Sub-agent sessions inherit security constraints
- Session isolation is maintained

### `command-guard` — Dangerous Command Prevention

**Trigger:** `before_tool_call` (specifically `exec` calls).

Additional guard layer for shell commands. Catches dangerous patterns that might slip through tier classification:
- Recursive deletes without safeguards
- Process kills that could affect system stability
- Network configuration changes
- Package installations from untrusted sources

## Automation Hooks

### `auto-git-commit` — Automatic Version Control

**Trigger:** `after_tool_call` — fires after tool calls that modify files.

When the agent writes or edits files, this hook automatically commits the changes to git. Features:

- **Debouncing** — waits 5 minutes after the last file change before committing (prevents 50 commits during a coding session)
- **Ignore list** — skip auto-generated files (MEMORY.md, logs, data files)
- **Repo-specific patterns** — different commit message formats for different repos
- **Smart messages** — generates commit messages from the changes, not just "auto-commit"

Why this matters: without auto-commit, the agent's work exists only in the filesystem. One bad `rm` or a server crash, and it's gone. Git is your safety net.

### `auto-task-capture` — Activity Detection

**Trigger:** `after_tool_call` — detects task-like activities.

Watches for patterns that suggest work is happening but wasn't tracked:
- File creation in project directories
- Multiple edits to the same file
- Command sequences that suggest debugging or deployment

Creates tasks automatically when detected. This is the safety net for Rule Zero violations — even if the agent forgets to track, this hook catches most activity.

### `auto-canvas-save` — Canvas State Preservation

**Trigger:** After canvas operations.

Saves canvas states (HTML, images) to the `canvas/` directory automatically. Prevents loss of visual work.

## Observability Hooks

### `llm-observer` — Token & Cost Tracking

**Trigger:** After LLM API calls.

Tracks:
- Token usage per model (input, output, cache)
- Cost per call and cumulative daily cost
- Model distribution (which models are being used)
- Session-level aggregation

Writes JSONL logs that feed into the dashboard's System tab.

### `message-logger` — Full Message Log

**Trigger:** All messages (sent and received).

Logs every message in and out. Essential for debugging and auditing. Keep logs rotated — they grow fast.

### `message-integrity` — Message Verification

**Trigger:** Message events.

Verifies message integrity — detects tampering or unexpected modifications to messages in transit. More relevant in multi-agent setups.

### `delegation-audit` & `delegation-policy` — Sub-Agent Governance

**Trigger:** Sub-agent spawn events.

- `delegation-audit` — logs every sub-agent spawn with context (who spawned it, why, what task)
- `delegation-policy` — enforces rules about sub-agent spawning (limits, allowed operations, required task tracking)

Cross-reference: see [Chapter 13](13-sub-agents.md) for the full sub-agent orchestration model — when to spawn, parallel execution patterns, verification, and the "create task before spawning" rule.

## A2A Hooks (Agent-to-Agent)

If you're running agent-to-agent communication (see Chapter 12):

### `a2a-gate` — Inter-Agent Access Control

**Trigger:** A2A message events.

Gates all agent-to-agent interactions. Verifies:
- Message authenticity (HMAC signatures)
- Sender authorization
- Content safety (no credential requests, no instruction injection)

### `a2a-audit-logger` — Cross-Agent Activity Log

**Trigger:** All A2A events.

Comprehensive logging of inter-agent communication for security review and debugging.

### `task-enforcer` — A2A Task Tracking

**Trigger:** A2A context events.

Ensures that work triggered by other agents is properly tracked in the task system. Prevents "invisible work" that doesn't appear in the dashboard.

## Hooks vs Skills

A common point of confusion: hooks and skills are different mechanisms.

- **Hooks** run automatically at the platform level. The agent doesn't choose to trigger them — they fire on events (tool calls, session starts, messages). The agent can't bypass them.
- **Skills** are instruction sets the agent reads on demand. They teach the agent how to use tools and APIs. The agent chooses when to load them.

Use hooks for enforcement (security, automation, logging). Use skills for guidance (tool instructions, workflow procedures). See [Chapter 14](14-skills.md) for the full skills system.

## Building Your Own Hooks

Start with these priorities:

1. **`the-wall`** (credential scanning + tier classification) — this is your most important hook
2. **`agent-firewall`** (session security injection) — second most important
3. **`auto-git-commit`** (automatic version control) — prevents work loss
4. **`llm-observer`** (cost tracking) — know what you're spending

Add more hooks as your needs evolve. Each hook should do one thing well.

### Hook Development Tips

- **Keep hooks fast** — they run on every event. A slow hook slows everything.
- **Fail safe** — if a security hook errors, it should block (not allow) the action
- **Log everything** — you can always reduce logging later; you can't retroactively log things that weren't captured
- **Test with real traffic** — hooks that work in testing may behave differently under real agent workloads
- **Version your configs** — autonomy tiers and hook configs should be in git

## What to Build

- [ ] Build `the-wall` — credential scanning + autonomy tiers + audit logging
- [ ] Build `agent-firewall` — security constraint injection at session start
- [ ] Build `auto-git-commit` — automatic version control with debouncing
- [ ] Build `llm-observer` — token and cost tracking
- [ ] Create `config/autonomy-tiers.json` — define your tier classifications
- [ ] Set up audit log rotation for `logs/the-wall.jsonl`
- [ ] Register hooks in `openclaw.json`
- [ ] Test credential scanning with known patterns (use test strings, not real keys)
- [ ] Test tier classification for your most common tool calls

---

*Previous: [Chapter 3 — Task Management](03-task-management.md) | Next: [Chapter 5 — Security](05-security.md)*
