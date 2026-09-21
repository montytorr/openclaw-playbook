# Chapter 9: Configuration

OpenClaw is configured through `openclaw.json` and environment variables. This chapter covers the structure and key settings, not the full reference (check OpenClaw docs for that), but the operational patterns that matter.

## openclaw.json Overview

The main configuration file lives at `~/.openclaw/openclaw.json` (or wherever your OpenClaw installation expects it). It controls:

- Agent definitions and workspace paths
- Model selection and fallbacks
- Channel connections (Discord, Telegram, etc.)
- Hook registration
- Cron job definitions
- Plugin configuration
- Native memory configuration
- TTS settings
- Message formatting

## Key Sections

### Agent Configuration

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "<PROVIDER>/<PRIMARY_MODEL>",
        "fallbacks": ["<PROVIDER>/<ROUTINE_MODEL>"]
      },
      "models": {
        "<PROVIDER>/<PRIMARY_MODEL>": { "alias": "primary" },
        "<PROVIDER>/<ROUTINE_MODEL>": { "alias": "routine" }
      },
      "workspace": "/root/clawd",
      "thinkingDefault": "medium",
      "subagents": {
        "thinking": "off"
      },
      "bootstrapMaxChars": 20000,
      "bootstrapTotalMaxChars": 50000
    },
    "entries": {
      "main": {
        "workspace": "/absolute/path/to/workspace",
        "model": {
          "primary": "<PROVIDER>/<PRIMARY_MODEL>",
          "fallbacks": ["<PROVIDER>/<ROUTINE_MODEL>"]
        }
      }
    },
    "ownership": "explicit"
  }
}
```

Key decisions:
- **One main agent first** — keep the initial deployment simple, then add explicit specialist entries only when their workspace, channel binding, and memory boundary are genuinely different.
- **Explicit ownership** — bind channels to the intended agent rather than relying on historical default routing.
- **Bootstrap files** — these are injected into every session as project context. Order matters (most important first).
- **Bootstrap size limits** — prevent massive files from consuming the entire context window.

### Native Memory Configuration

Prefer **OpenClaw native local memory** where the installed release supports it;
verify the schema and command against that release.

A practical baseline looks like this:

```json
{
  "memory": {
    "search": {
      "enabled": true,
      "provider": "local",
      "fallback": "none",
      "sources": ["memory"],
      "experimental": {
        "sessionMemory": false
      },
      "rememberAcrossConversations": false
    }
  }
}
```

What this gets you:
- local embeddings/vector/FTS-backed retrieval
- canonical `MEMORY.md`, `memory/*.md`, and selected extra paths as search sources
- fewer migration traps than older bolt-on memory stacks

Operationally:
- verify health with `openclaw memory status --deep`
- keep `MEMORY.md` as a digest, not the primary search engine
- start with `sources: ["memory"]`; add transcript/session recall only after measuring its storage, latency, retention, and privacy cost
- expose memory search only to the main/private agent path unless a specialist has an explicit, least-privilege corpus
- treat dreaming as optional synthesis on top of retrieval, not a substitute for retrieval itself

### Model Configuration

Choose providers based on current support and account health. Do not encode a
provider migration or OAuth claim as a universal rule; verify it for the installed
release and document the tested fallback path.

A solid provider-neutral model setup looks like this:

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "<PROVIDER>/<PRIMARY_MODEL>",
        "fallbacks": ["<PROVIDER>/<ROUTINE_MODEL>"]
      },
      "models": {
        "<PROVIDER>/<PRIMARY_MODEL>": { "alias": "primary" },
        "<PROVIDER>/<ROUTINE_MODEL>": { "alias": "routine" }
      },
      "thinkingDefault": "medium",
      "subagents": {
        "thinking": "off"
      },
      "imageGenerationModel": {
        "primary": "openai/gpt-image-1"
      }
    }
  },
  "plugins": {
    "allow": ["discord", "browser", "openai", "memory-core", "diagnostics-otel", "codex"],
    "slots": {
      "memory": "memory-core"
    },
    "entries": {
      "codex": {
        "enabled": true,
        "config": {
          "appServer": {
            "approvalPolicy": "never"
          }
        }
      },
      "memory-core": {
        "enabled": true
      },
      "diagnostics-otel": {
        "enabled": true,
        "config": {}
      }
    }
  }
}
```

Current releases keep OTEL exporter settings under top-level `diagnostics.otel` (for example `endpoint: "http://127.0.0.1:4318"`) while the bundled plugin entry remains enabled with an empty config object. Validate this against the installed schema; older releases used different plugin-local keys.

Configure provider authentication with the installed release's setup/config helpers and protected secret store. Do not cargo-cult an old provider profile name into a new runtime: provider IDs and OAuth ownership have changed across releases.

If you use OpenClaw native memory, do **not** keep stale legacy memory aliases in `plugins.allow` just to make old docs happy. Prefer the native memory stack and, if needed, bind the memory slot to `memory-core` instead of carrying a dead plugin name forever.

### Codex Plugin And Runtime Operations

If you are running a Codex-first setup, document the actual runtime path explicitly instead of treating it like an invisible implementation detail.

The practical baseline is:

```json
{
  "plugins": {
    "entries": {
      "codex": {
        "enabled": true,
        "config": {
          "appServer": {
            "approvalPolicy": "never"
          }
        }
      }
    }
  }
}
```

Why this matters:
- the app-server path is part of the real runtime, not just a hidden helper
- approval behavior should be intentional, not whatever the current default happens to be
- Codex auth/runtime failures often show up through runtime-state drift before they become obvious elsewhere

This does **not** mean "disable human approval for every risky action." It means the internal Codex app-server command lane should not keep interrupting normal operation with approval prompts when your intended policy is autonomous internal execution.

Operationally, treat these as separate things:
- model routing
- Codex auth profile completeness
- embedded Codex bridge/home health
- stale pinned session state

Changing only the model catalog is not enough if the runtime path is unhealthy or stale sessions keep dragging old state around.

### Codex OAuth Profile Hygiene

If your provider uses rotating OAuth tokens, do not casually copy one refresh token into multiple auth profiles or embedded bridge homes. That can create `refresh_token_reused` failures where one lane silently invalidates another.

Operationally:
- keep one canonical account/profile per provider unless you have a deliberate multi-account setup
- remove obsolete `default` profiles after migrating to a named account profile
- ensure embedded bridge homes and app-server state point at the same canonical profile
- make your sync script delete stale profiles rather than preserving every historical shape forever
- verify with a health script after restarts and package updates

The durable rule is simple: one rotating token should have one owner.

**Model strategy:**
- `<PRIMARY_MODEL>` for the main agent and heavier reasoning work
- `<ROUTINE_MODEL>` as the verified fallback and routine-work lane
- main session default thinking: `medium`
- sub-agent default thinking: `off` (escalate only when needed)
- per-cron overrides based on workload, not habit
- image generation model remains separate from chat model

### Quota-Aware Mini Routing

Keep the catalog boring: one verified primary and one verified fallback. Do not add
optional fast lanes unless an account-scoped probe proves they are usable.

The production-safe pattern is:
- keep the verified primary as primary
- keep the verified routine model as the real fallback
- use the routine model for mechanical maintenance
- reserve the primary for main conversations, reviews, synthesis, and high-stakes work
- verify routing with actual runtime status, not just model catalog strings

Why? Because fallback models should be dependable. Optional fast lanes are useful only after they are proven live for the account and kept out of the hard fallback chain.

A practical router policy looks like:
- high complexity -> verified primary model
- medium complexity -> verified routine model unless quality matters more than cost
- low complexity -> verified routine model with low/off thinking
- unknown or high-stakes -> verified primary model

This is also the cleanest place to express real-time quota policy, because OpenClaw's built-in status surfaces provider/account usage well, but not every model-specific edge case.

### A Practical Thinking Policy

This ended up being the useful split in production:

| Workload | Model | Thinking |
|---|---|---|
| Main conversations | verified primary | intentional budget |
| High-frequency cron/reactor checks | verified routine model | low |
| Mechanical watchdog loops | verified routine model | disabled / off |
| Nightly reviews, retros, strategy | verified primary | intentional budget |
| Sub-agents by default | inherited / override | `off` |

The principle is simple: **don't spend reasoning where there is no reasoning to do.**

### Runtime Checks That Actually Matter

For a live Codex deployment, verify runtime truth, not config aesthetics.

At minimum, your local operational checks should tell you:
- which runtime mode/path and fallback policy are active
- whether the Codex auth profile is complete
- whether any provider-specific bridge/home state is healthy, if applicable
- whether any ambiguous or stale pinned session lanes still exist

The exact script names are up to you, but the pattern matters. A `status-report` that only covers CPU, Docker, and network health is incomplete if your real failure mode lives in the Codex bridge or runtime path.

Useful checks usually include:
- `status-report`
- a focused runtime health script
- direct config inspection for the intended app-server policy
- auth profile inventory that catches duplicate/stale Codex profiles
- gateway service limits and current RSS checks when the gateway is a long-lived Node process

### Failure Classes To Expect

The annoying but real production failure classes are:
- **config drift** — the intended policy or routing changed silently
- **stale pinned sessions** — old session state keeps surfacing dead provider or approval behavior
- **auth/runtime drift** — provider token or runtime state becomes incomplete or stale

The pattern to document is not "we changed one config key and everything was fine." The pattern is "we verified the actual runtime path after restart/update and treated runtime evidence as the source of truth."

### Provider Migration Checklist

If you're moving from one provider stack to another, do all of it or you'll get weird half-migrated behavior:

1. update agent defaults (`primary`, `fallbacks`, aliases)
2. remove the old auth profile and provider ordering
3. update cron payload models
4. normalize cron `thinking` settings job-by-job
5. check sub-agent defaults (`subagents.thinking`)
6. verify only the intended live agent remains active
7. clear stale cron `sessionKey` pinning if historical sessions keep surfacing old provider metadata
8. verify with config inspection / grep that the old provider no longer appears in live config
9. verify auth profile uniqueness so old bridge homes cannot reuse a rotating token

The annoying truth: changing only the main model is not enough. Crons and old pinned sessions will happily keep dragging dead provider assumptions around.

### Channel Configuration

```json
{
  "channels": {
    "discord": {
      "token": "<YOUR_DISCORD_BOT_TOKEN>",
      "allowedChannels": ["<CHANNEL_ID_1>", "<CHANNEL_ID_2>"],
      "prefix": "!"
    }
  }
}
```

Each channel type (Discord, Telegram, Slack) has its own configuration block. Key settings:
- Authentication token
- Allowed channels/chats (restrict where the agent responds)
- Command prefix (if applicable)
- Message formatting options

### Hook Registration

```json
{
  "hooks": [
    {
      "name": "the-wall",
      "path": "hooks/the-wall/index.ts",
      "events": ["before_tool_call"],
      "enabled": true
    },
    {
      "name": "agent-firewall",
      "path": "hooks/agent-firewall/index.ts",
      "events": ["session_start"],
      "enabled": true
    },
    {
      "name": "auto-git-commit",
      "path": "hooks/auto-git-commit/index.ts",
      "events": ["after_tool_call"],
      "enabled": true
    }
  ],
  "plugins": {
    "allow": ["discord", "browser", "openai", "diagnostics-otel"],
    "entries": {
      "diagnostics-otel": {
        "enabled": true,
        "config": {}
      }
    }
  }
}
```

Hook paths are relative to the workspace. Register hooks in priority order, security hooks first. For LLM telemetry, prefer the bundled `diagnostics-otel` plugin over a workspace `llm-observer` hook.

### Automation Configuration

```json
openclaw cron list --json
openclaw cron add --help
```

Current OpenClaw releases manage automations through the Gateway rather than a `cron.jobs` block in `openclaw.json`. Use the installed CLI/schema as authority, inspect the created job, and run it once before trusting its schedule. Keep deterministic shell checks in host cron or systemd; use OpenClaw automations only when a model turn, agent context, or channel delivery is required.

If you migrate providers, do the cleanup properly:
- remove the old auth profile and provider order
- update cron payload models, not just agent defaults
- normalize thinking levels job-by-job
- clear stale `sessionKey` pinning on cron jobs if old sessions keep surfacing legacy model metadata
- verify with greps or config inspection that no old provider strings remain in active config
- if you keep optional fast-lane models, make sure cron jobs route through the same live policy rather than pinning them blindly

Cross-reference: see Chapter 6 for cron patterns and the heartbeat vs cron decision tree.

### TTS Configuration

```json
{
  "tts": {
    "auto": "inbound",
    "provider": "elevenlabs",
    "providers": {
      "elevenlabs": {
        "apiKey": "<YOUR_KEY_HERE>",
        "modelId": "<YOUR_TTS_MODEL_ID>",
        "speakerVoiceId": "<YOUR_VOICE_ID>"
      }
    }
  }
}
```

TTS (text-to-speech) lets your agent respond with voice messages. The `auto: "inbound"` setting means the agent automatically replies with audio when the human sends a voice message. Store the provider key through the host's protected config/secret workflow rather than committing the placeholder shape.

### Plugin Configuration

```json
{
  "plugins": {
    "entries": {
      "memory-core": {
        "enabled": true,
        "config": {}
      }
    }
  }
}
```

Plugins extend OpenClaw's capabilities. Use `plugins.slots.memory` to select the installed memory implementation instead of relying on a historical plugin alias. For telemetry, enable the bundled `diagnostics-otel` plugin and configure the exporter under top-level `diagnostics.otel`.

## Environment Variables

Create a `.env` file in your workspace root (git-ignored):

```bash
# LLM / auth
# If using OpenAI APIs directly for media/image/etc.
OPENAI_API_KEY=<YOUR_KEY_HERE>

# Note: Codex chat auth may be OAuth-based rather than raw API-key based,
# depending on your OpenClaw provider setup.

# Channel Tokens
DISCORD_BOT_TOKEN=<YOUR_KEY_HERE>
TELEGRAM_BOT_TOKEN=<YOUR_KEY_HERE>

# TTS
ELEVENLABS_API_KEY=<YOUR_KEY_HERE>

# Monitoring
BETTERSTACK_API_KEY=<YOUR_KEY_HERE>

# Email (if using AgentMail or similar)
AGENTMAIL_API_KEY=<YOUR_KEY_HERE>

# Trading (if applicable)
ALPACA_API_KEY=<YOUR_KEY_HERE>
ALPACA_SECRET_KEY=<YOUR_KEY_HERE>

# Gateway
OPENCLAW_GATEWAY_TOKEN=<YOUR_KEY_HERE>
```

**Security rules for .env:**
- NEVER commit to git (ensure it's in .gitignore)
- The agent should NEVER read or output .env contents
- Use environment variable references in config, not raw values
- Rotate keys periodically

## Configuration Patterns

### Minimal Starter Config

For a fresh setup, start with:
1. One agent (`main`)
2. One auth profile and one provider path you trust
3. One channel (Discord or Telegram)
4. Two hooks (`the-wall` + `agent-firewall`)
5. One cron job (heartbeat)
6. Basic model configuration

Add complexity incrementally. A config with 17 hooks and 20 cron jobs didn't happen on day one — it grew over months.

### Testing Configuration Changes

```bash
# Validate config syntax
cat ~/.openclaw/openclaw.json | python3 -m json.tool

# Validate against the installed release
openclaw config validate

# On a chat-critical host, request a guarded/deferred restart
/opt/openclaw/scripts/gateway-restart-safe --reason "validated config change" --defer

# Check gateway logs for errors
openclaw gateway logs
```

Always validate against the installed schema before restarting. Valid JSON can still contain retired keys. On a chat-critical host, do not let an agent call `openclaw gateway restart` directly during an active run; use an operator-owned guard that can defer until the channel is quiet, then verify the resulting service owner and health.

For provider migrations, also verify semantics — not just syntax. A config can be perfectly valid JSON and still be operationally broken because some cron payloads or auth order still point at the dead provider.

### Backup Strategy

```bash
# Backup config before changes
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.bak.$(date +%Y%m%d)

# Or use git
cd ~/.openclaw && git init && git add openclaw.json && git commit -m "config backup"
```

## The Example Config

See `templates/openclaw.example.json` for a complete skeleton with placeholder values. It includes every section documented here with explanatory structure.

## What to Build

- [ ] Create your `openclaw.json` starting from the example template
- [ ] Set up `.env` with your API keys
- [ ] Configure your primary channel (Discord or Telegram)
- [ ] Register your first hooks (security hooks first)
- [ ] Set up the heartbeat cron job
- [ ] Add model configuration with fallback
- [ ] Validate your config with `openclaw config validate` and use a guarded/deferred restart path on chat-critical hosts
- [ ] Verify runtime truth after restart: provider status, auth profile health, gateway service limits, and stale pinned sessions
- [ ] Set up config backups (git or manual copies)
- [ ] Document any non-obvious settings in TOOLS.md

---

*Previous: [Chapter 8 — Dashboard](08-dashboard.md) | Next: [Chapter 10 — Clones](10-clones.md)*
