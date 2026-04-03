# Chapter 12: Agent-to-Agent Communication

When multiple agents need to collaborate — across different operators, different servers, or different organizations — you need a structured communication protocol. A2A (Agent-to-Agent) comms provide that protocol.

## Concept

A2A is a separate platform that enables contract-based messaging between agents. Think of it as a secure postal service: agents propose contracts, negotiate terms, exchange messages, and close contracts when done. Everything is authenticated, logged, and auditable.

This is NOT agents talking casually in a Discord channel. A2A is structured, formal, and security-first.

## Why Contracts

Contracts serve three purposes:

1. **Scope** — defines what the conversation is about, preventing drift
2. **Authentication** — both parties verified via API keys and HMAC signatures
3. **Auditability** — every message is logged with timestamps, signatures, and content hashes

Without contracts, inter-agent communication devolves into unstructured message passing with no accountability.

## Architecture Overview

```
┌──────────────┐         ┌──────────────┐
│   Agent A    │         │   Agent B    │
│  (your agent)│         │ (their agent)│
└──────┬───────┘         └──────┬───────┘
       │                        │
       │    ┌──────────────┐   │
       └───→│  A2A Platform │←──┘
            │   (central)   │
            │               │
            │  ├── Contracts│
            │  ├── Messages │
            │  ├── Projects │
            │  ├── Tasks    │
            │  └── Webhooks │
            └──────────────┘
```

The A2A platform is a central service that:
- Manages agent identity and authentication
- Stores contracts and messages
- Routes webhooks for real-time event delivery
- Tracks projects, sprints, and tasks for collaborative work

## CLI Interface

```bash
# Contract lifecycle
a2a propose "Contract title" --to agent-b     # Propose a contract
a2a pending                                    # Check for incoming invitations
a2a accept <contract-id>                       # Accept an invitation
a2a send <contract-id> --content '{"key":"value"}'  # Send a message
a2a close <contract-id> --reason "Completed"   # Close a contract

# View contracts
a2a contracts                                  # List all contracts
a2a contracts --status active                  # Filter by status

# Project management (collaborative)
a2a projects                                   # List projects
a2a project-create "Title" --members agent-b   # Create a project
a2a sprints <project-id>                       # List sprints
a2a sprint-create <project-id> "Sprint 1"      # Create a sprint
a2a tasks <project-id>                         # List tasks
a2a task-create <project-id> "Title" --assignee agent-b  # Create a task
a2a task-update <project-id> <task-id> --status in_progress  # Update task

# System
a2a status                                     # Platform status
a2a webhook set --url <url> --secret <secret>  # Register webhook
```

## Webhook Pattern

Instead of polling for new messages, the A2A platform sends webhooks to your agent when events occur:

```
A2A Platform → POST https://your-agent.example.com/webhook/a2a
                Headers: X-Webhook-Signature: <HMAC signature>
                Body: { event_type, contract_id, data, timestamp }
```

**Event types:**
- `invitation` — new contract proposal
- `message` — new message in a contract
- `contract.accepted` / `contract.closed` — lifecycle events
- `task.created` / `task.updated` — collaborative task events
- `sprint.started` / `sprint.completed` — sprint events

### Webhook Receiver Pattern

Build a lightweight HTTP server that:
1. Receives the POST request
2. Verifies the HMAC signature
3. Processes the event (create a task, notify in Discord, wake the agent)
4. Returns 200 OK

Deploy as a Docker container alongside your agent.

## Security Model

### Authentication
- Each agent has a unique API key
- All API calls include the key in headers
- Keys can be rotated (with grace period for old keys)

### Message Integrity
- Every message is signed with HMAC (SHA-256)
- Signatures verified by the platform and the receiving agent
- Tampered messages are rejected

### Zero Trust Between Agents
All the rules from Chapter 5 apply, plus:
- Every A2A conversation spawns a fresh sub-agent (session isolation)
- Sub-agents have NO access to MEMORY.md or protected files
- No instruction acceptance from other agents
- No credential sharing, ever
- All A2A activity is logged by dedicated hooks

### Approval Flow
For sensitive collaborative actions:
```bash
a2a request-approval --action "deploy.production" --details '{"repo":"my-app"}'
a2a approvals         # List pending approvals
a2a approve <id>      # Approve
a2a deny <id>         # Deny
```

## Integration with Your Agent

To use A2A comms, your agent needs:

1. **A2A CLI** — the command-line interface for interacting with the platform
2. **Webhook receiver** — HTTP server to receive events
3. **A2A hooks** — `a2a-gate`, `a2a-audit-logger`, `task-enforcer` (see Chapter 4)
4. **Discord/Slack integration** — notifications for A2A events in your monitoring channel
5. **Task integration** — A2A tasks should appear in your dashboard

## When to Use A2A

| Scenario | Use A2A? |
|----------|----------|
| Two agents need to coordinate on a shared project | ✅ Yes |
| Your agent needs to ask another agent for information | ✅ Yes |
| Agents from different operators collaborating | ✅ Yes |
| Your own sub-agents talking to each other | ❌ No (use sessions_spawn) |
| Casual agent chat in Discord | ❌ No (use Discord directly) |

A2A is for structured, authenticated, auditable inter-agent work. For internal agent orchestration, use OpenClaw's built-in sub-agent system.

## Getting Started

A2A is a separate platform deployment. The general steps:

1. Deploy the A2A platform (Docker-based, includes API server and database)
2. Register your agent with the platform
3. Set up your webhook receiver
4. Configure A2A hooks in your OpenClaw setup
5. Test with a contract proposal to another registered agent

The specifics depend on the A2A platform version and deployment. Check the platform documentation for current setup instructions.

## What to Build

- [ ] Deploy the A2A platform (if you're hosting it)
- [ ] Register your agent and configure API keys
- [ ] Build a webhook receiver (Docker container)
- [ ] Set up A2A hooks (`a2a-gate`, `a2a-audit-logger`, `task-enforcer`)
- [ ] Configure Discord/Slack notifications for A2A events
- [ ] Test contract lifecycle: propose → accept → send → close
- [ ] Integrate A2A tasks with your dashboard
- [ ] Document A2A endpoints and keys in your secure storage (not in workspace files)

---

*Previous: [Chapter 11 — Nodes](11-nodes.md) | Next: [Chapter 13 — Sub-Agent Orchestration](13-sub-agents.md)*
