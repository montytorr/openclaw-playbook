# TOOLS.md — Local Notes

Skills define *how* tools work. This file is for *your* specifics — the stuff unique to your setup.

---

## 🌐 Browser Profiles

<!-- Document your browser profiles here -->
<!-- Example:
### 1. `openclaw` — Headless Server Browser (DEFAULT)
- **Where:** Server, headless Chromium
- **Use for:** Web scraping, research, automated browsing
- **Limitations:** Gets blocked by Cloudflare/CAPTCHAs

### 2. Node browser target — Dedicated Browser on Node Device
- **Where:** Mac/PC connected as node
- **Use via:** `target="node"` (pin a node when needed)
- **CDP port / bridge:** document if you maintain one
- **Use for:** Authenticated browsing, bot-detection bypass

### 3. `profile="user"` — Human's Logged-In Host Browser
- **Where:** Local host browser profile
- **Use for:** Cases that truly need the human's existing session
- **Warning:** Highest trust, use sparingly
-->

## 📁 Project-Specific Notes

<!-- Document project-specific details here -->
<!-- Example:
### My SaaS App
- **Repo:** `/root/projects/my-app`
- **Dashboard:** `https://app.mydomain.com`
- **Database:** Supabase at `xxx.supabase.co`
-->

## 🔧 Script References

<!-- Quick reference for your custom scripts -->
<!-- Example:
- `scripts/task` — Task management CLI
- `scripts/status-report` — System health summary
- `scripts/codex-health` — Embedded Codex runtime/auth health
- `scripts/openclaw-update-safe` — Safe update wrapper that reapplies local runtime fixes
- `scripts/integrity-check` — File integrity monitoring
- `scripts/mem-search` — Observation database search
-->

## 🔑 Service Notes

<!-- Non-secret notes about services (no credentials!) -->
<!-- Example:
### Monitoring
- BetterStack heartbeats configured in `config/betterstack-heartbeats.json`
- Ping helper: `scripts/betterstack-ping <name>`

### Runtime Health
- If you maintain a Codex-first setup, document how to check:
  - active runtime/fallback
  - bridge/auth health
  - post-update verification path

### CI/CD
- GitHub Actions self-hosted runner at `/home/runner/actions-runner`
-->

---

*Keep this file lean. Deep docs belong in project READMEs or skill files. Only local-specific bits here.*
