# Chapter 9: Configuration

OpenClaw is configured through `openclaw.json` and environment variables. This chapter covers the structure and key settings — not the full reference (check OpenClaw docs for that), but the operational patterns that matter.

## openclaw.json Overview

The main configuration file lives at `~/.openclaw/openclaw.json` (or wherever your OpenClaw installation expects it). It controls:

- Agent definitions and workspace paths
- Model selection and fallbacks
- Channel connections (Discord, Telegram, etc.)
- Hook registration
- Cron job definitions
- Plugin configuration
- TTS settings
- Message formatting

## Key Sections

### Agent Configuration

```json
{
  "agents": {
    "defaults": {
      "model": "anthropic/claude-sonnet-4-20250514",
      "workspace": "/root/clawd",
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
        "name": "Your Agent",
        "model": "anthropic/claude-sonnet-4-20250514"
      }
    ]
  }
}
```

Key decisions:
- **One agent per instance** — keep it simple. One `main` agent per OpenClaw installation.
- **Bootstrap files** — these are injected into every session as project context. Order matters (most important first).
- **Bootstrap size limits** — prevent massive files from consuming the entire context window.

### Model Configuration

```json
{
  "agents": {
    "defaults": {
      "model": "anthropic/claude-sonnet-4-20250514",
      "fallbackModel": "anthropic/claude-haiku-3-20250722",
      "imageGenerationModel": {
        "primary": "openai/gpt-image-1"
      }
    }
  }
}
```

**Model strategy:**
- Primary model for main conversations (quality matters)
- Cheaper fallback for high-volume operations (cron jobs, automated checks)
- Per-session overrides for specific cron jobs that need different capabilities
- Image generation model (separate from chat model)

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
    },
    {
      "name": "llm-observer",
      "path": "hooks/llm-observer/index.ts",
      "events": ["after_llm_call"],
      "enabled": true
    }
  ]
}
```

Hook paths are relative to the workspace. Register hooks in priority order — security hooks first.

### Cron Configuration

```json
{
  "cron": {
    "jobs": [
      {
        "id": "morning-brief",
        "schedule": "30 8 * * 1-5",
        "timezone": "Europe/Paris",
        "type": "agentTurn",
        "prompt": "Generate morning briefing...",
        "delivery": {
          "type": "announce",
          "channel": "<CHANNEL_ID>"
        }
      },
      {
        "id": "heartbeat",
        "schedule": "*/30 * * * *",
        "type": "systemEvent",
        "prompt": "Read HEARTBEAT.md if it exists..."
      }
    ]
  }
}
```

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

Plugins extend OpenClaw's capabilities. The `device-pair` plugin enables companion device connections (see Chapter 11).

## Environment Variables

Create a `.env` file in your workspace root (git-ignored):

```bash
# LLM Provider Keys
ANTHROPIC_API_KEY=<YOUR_KEY_HERE>
OPENAI_API_KEY=<YOUR_KEY_HERE>

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
2. One channel (Discord or Telegram)
3. Two hooks (`the-wall` + `agent-firewall`)
4. One cron job (heartbeat)
5. Basic model configuration

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
- [ ] Set up config backups (git or manual copies)
- [ ] Document any non-obvious settings in TOOLS.md

---

*Previous: [Chapter 8 — Dashboard](08-dashboard.md) | Next: [Chapter 10 — Clones](10-clones.md)*
