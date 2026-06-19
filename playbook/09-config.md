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
        "primary": "openai-codex/gpt-5.5",
        "fallbacks": ["openai-codex/gpt-5.5-mini"]
      },
      "models": {
        "openai-codex/gpt-5.5": { "alias": "codex" },
        "openai-codex/gpt-5.5-mini": { "alias": "mini" }
      },
      "workspace": "/root/clawd",
      "thinkingDefault": "medium",
      "subagents": {
        "thinking": "off"
      },
      "bootstrapFiles": [
        "AGENTS.md",
        "SOUL.md",
        "IDENTITY.md",
        "USER.md",
        "TOOLS.md"
      ],
      "bootstrapMaxChars": 20000,
      "bootstrapTotalMaxChars": 50000
    },
    "list": [
      {
        "id": "main",
        "name": "Your Agent"
      }
    ]
  }
}
```

Key decisions:
- **One agent per instance** — keep it simple. One `main` agent per OpenClaw installation.
- **Bootstrap files** — these are injected into every session as project context. Order matters (most important first).
- **Bootstrap size limits** — prevent massive files from consuming the entire context window.

### Native Memory Configuration

As of April 2026, the sane default is to use **OpenClaw native local memory** rather than leaning on a legacy external memory plugin name.

A practical baseline looks like this:

```json
{
  "memorySearch": {
    "provider": "local",
    "fallback": "none",
    "sources": ["memory", "sessions"]
  }
}
```

What this gets you:
- local embeddings/vector/FTS-backed retrieval
- `memory/*.md` and indexed session history as search sources
- fewer migration traps than older bolt-on memory stacks

Operationally:
- verify health with `openclaw memory status --deep`
- keep `MEMORY.md` as a digest, not the primary search engine
- treat dreaming as optional synthesis on top of retrieval, not a substitute for retrieval itself

### Model Configuration

As of the 2026.6 runtime line, one practical production pattern is **Codex-only routing**.

Why? Because Anthropic Claude OAuth no longer reliably works with OpenClaw in the way many early setups depended on. If your system was built around Claude OAuth, assume that path may break and document a provider migration strategy.

A solid Codex setup looks like this:

```json
{
  "auth": {
    "profiles": {
      "openai-codex:default": {
        "provider": "openai-codex",
        "mode": "oauth"
      }
    },
    "order": {
      "openai-codex": ["openai-codex:default"]
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "openai-codex/gpt-5.5",
        "fallbacks": ["openai-codex/gpt-5.5-mini"]
      },
      "models": {
        "openai-codex/gpt-5.5": { "alias": "codex" },
        "openai-codex/gpt-5.5-mini": { "alias": "mini" }
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
    "allow": ["discord", "browser", "openai", "quota-aware-codex-router", "diagnostics-otel", "codex"],
    "entries": {
      "codex": {
        "enabled": true,
        "config": {
          "appServer": {
            "approvalPolicy": "never"
          }
        }
      },
      "quota-aware-codex-router": {
        "enabled": true,
        "config": {}
      },
      "diagnostics-otel": {
        "enabled": true,
        "config": {
          "otlpHttpEndpoint": "http://127.0.0.1:4318/v1"
        }
      }
    }
  }
}
```

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
- `gpt-5.5` (`codex`) for the main agent and heavier reasoning work
- `gpt-5.5-mini` (`mini`) as the stable fallback and routine-work lane
- main session default thinking: `medium`
- sub-agent default thinking: `off` (escalate only when needed)
- per-cron overrides based on workload, not habit
- image generation model remains separate from chat model

### Quota-Aware Mini Routing

As of the 2026.6 runtime line, keep the catalog boring: `gpt-5.5` primary, `gpt-5.5-mini` fallback. Do not keep stale optional fast-lane aliases in current examples unless your account has a separately verified lane and you actively route to it.

The production-safe pattern is:
- keep `gpt-5.5` as primary
- keep `gpt-5.5-mini` as the real fallback
- use `gpt-5.5-mini` for routine crons/reactors and low-ambiguity maintenance
- reserve `gpt-5.5` for main conversations, reviews, synthesis, and high-stakes work
- verify routing with actual runtime status, not just model catalog strings

Why? Because fallback models should be dependable. Optional fast lanes are useful only after they are proven live for the account and kept out of the hard fallback chain.

A practical router policy looks like:
- high complexity -> `gpt-5.5`
- medium complexity -> `gpt-5.5-mini` unless quality matters more than cost
- low complexity -> `gpt-5.5-mini` with low/off thinking
- unknown or high-stakes -> `gpt-5.5`

This is also the cleanest place to express real-time quota policy, because OpenClaw's built-in status surfaces provider/account usage well, but not every model-specific edge case.

### A Practical Thinking Policy

This ended up being the useful split in production:

| Workload | Model | Thinking |
|---|---|---|
| Main conversations | `gpt-5.5` | `medium` |
| High-frequency cron/reactor checks | `gpt-5.5-mini` | `low` |
| Mechanical watchdog loops | `gpt-5.5-mini` | `disabled` / `off` |
| Nightly reviews, retros, strategy | `gpt-5.5` | `medium` |
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
        "config": {
          "otlpHttpEndpoint": "http://127.0.0.1:4318/v1"
        }
      }
    }
  }
}
```

Hook paths are relative to the workspace. Register hooks in priority order, security hooks first. For LLM telemetry, prefer the bundled `diagnostics-otel` plugin over a workspace `llm-observer` hook.

### Cron Configuration

```json
{
  "cron": {
    "jobs": [
      {
        "id": "morning-brief",
        "name": "Morning Briefing",
        "enabled": true,
        "schedule": {
          "kind": "cron",
          "expr": "30 8 * * 1-5",
          "tz": "<YOUR_TIMEZONE>"
        },
        "sessionTarget": "isolated",
        "payload": {
          "kind": "agentTurn",
          "message": "Generate morning briefing...",
          "model": "openai-codex/gpt-5.5",
          "thinking": "medium",
          "timeoutSeconds": 600
        },
        "delivery": {
          "mode": "announce",
          "channel": "<CHANNEL_ID>"
        }
      },
      {
        "id": "heartbeat",
        "name": "Heartbeat",
        "enabled": true,
        "schedule": {
          "kind": "cron",
          "expr": "*/30 * * * *"
        },
        "sessionTarget": "main",
        "payload": {
          "kind": "systemEvent",
          "text": "Read HEARTBEAT.md if it exists (workspace context). Follow it strictly. Do not infer or repeat old tasks from prior chats. If nothing needs attention, reply HEARTBEAT_OK."
        }
      }
    ]
  }
}
```

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
  "messages": {
    "tts": {
      "provider": "elevenlabs",
      "voice": "<YOUR_VOICE_ID>",
      "model": "eleven_multilingual_v2",
      "auto": "inbound",
      "fallback": {
        "provider": "openai",
        "voice": "fable"
      }
    }
  }
}
```

TTS (text-to-speech) lets your agent respond with voice messages. The `auto: "inbound"` setting means the agent automatically replies with audio when the human sends a voice message.

### Plugin Configuration

```json
{
  "plugins": {
    "entries": {
      "device-pair": {
        "enabled": true,
        "config": {
          "publicUrl": "https://your-gateway-url.com"
        }
      }
    }
  }
}
```

Plugins extend OpenClaw's capabilities. The `device-pair` plugin enables companion device connections (see Chapter 11). For telemetry, enable the bundled `diagnostics-otel` plugin and send OTLP to a local collector instead of relying on a custom workspace `llm-observer` hook.

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

# Restart gateway to apply changes
openclaw gateway restart

# Check gateway logs for errors
openclaw gateway logs
```

Always validate JSON syntax before restarting. A syntax error in `openclaw.json` can prevent the gateway from starting.

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
- [ ] Validate your config and test with `openclaw gateway restart`
- [ ] Verify runtime truth after restart: provider status, auth profile health, gateway service limits, and stale pinned sessions
- [ ] Set up config backups (git or manual copies)
- [ ] Document any non-obvious settings in TOOLS.md

---

*Previous: [Chapter 8 — Dashboard](08-dashboard.md) | Next: [Chapter 10 — Clones](10-clones.md)*
