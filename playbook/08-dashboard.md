# Chapter 8: Dashboard

An autonomous agent without visibility is a black box. The dashboard is your window into what the agent is doing, has done, and should be paying attention to.

## Concept

The dashboard is a web application that reads from the same data stores your agent uses — primarily SQLite databases — and presents them in a browsable UI. It's read-only (the dashboard doesn't modify agent state) and serves as the human's primary monitoring tool.

## Why Build a Dashboard

Without a dashboard, your monitoring options are:
- Ask the agent "what have you been doing?" (unreliable — it might not remember or might hallucinate)
- Read log files manually (tedious)
- Check individual systems one by one (time-consuming)

A dashboard gives you:
- **Real-time task visibility** — what's in progress, what's done, what's planned
- **Cost tracking** — how much you're spending on LLM calls per day/week/month
- **System health** — Docker containers, disk space, cron status at a glance
- **Trading visibility** — positions, P&L, trade history (if applicable)
- **Security overview** — audit logs, integrity status, hook activity

## Architecture

```
┌─────────────────────────────────────────┐
│              Web Browser                 │
│         (your dashboard UI)              │
└──────────────────┬──────────────────────┘
                   │ HTTPS
┌──────────────────┴──────────────────────┐
│           Reverse Proxy (Traefik)        │
│        TLS termination, auth             │
└──────────────────┬──────────────────────┘
                   │ HTTP
┌──────────────────┴──────────────────────┐
│           Dashboard Container            │
│        (Docker, reads SQLite DBs)        │
│                                          │
│  Tabs:                                   │
│  ├── Projects (tasks)                    │
│  ├── Trading (positions, P&L)            │
│  ├── System (health, costs)              │
│  └── Security (audit logs, integrity)    │
└──────────────────┬──────────────────────┘
                   │ File reads
┌──────────────────┴──────────────────────┐
│           Agent Workspace                │
│  ├── data/clawd.db (tasks, trades)       │
│  ├── logs/llm-observer.jsonl (costs)     │
│  ├── logs/the-wall.jsonl (audit)         │
│  └── canvas/security-overview.html       │
└──────────────────────────────────────────┘
```

## Recommended Tabs

### Projects Tab
**Data source:** Tasks SQLite table

Displays:
- Active tasks (in-progress) prominently at top
- Recent completed tasks with timestamps
- Planned tasks queue
- Filter by category, status, date range
- Task detail view (title, input, output, timestamps)

This is the most-used tab. It directly reflects Rule Zero compliance.

### System Tab
**Data sources:** `llm-observer` JSONL logs, system metrics

Displays:
- Daily/weekly/monthly LLM cost breakdown by model
- Token usage trends
- System health (CPU, RAM, disk — collected via cron)
- Docker container status
- Cron job execution history

### Security Tab
**Data sources:** `the-wall` audit JSONL, integrity baselines

Displays:
- Recent tier escalations (notify and approve actions)
- Blocked actions (credential leaks, dangerous commands)
- Integrity check status (last run, any mismatches)
- Embedded security overview page (static HTML)

### Trading Tab (Optional)
**Data source:** Trading database

Displays:
- Open positions with current P&L
- Trade history
- Performance metrics
- Only relevant if you're running trading operations

## Deployment

### Docker Compose

```yaml
version: '3.8'

services:
  dashboard:
    build: ./dashboard
    container_name: agent-dashboard
    restart: unless-stopped
    volumes:
      - /path/to/workspace/data:/data:ro          # SQLite databases (read-only)
      - /path/to/workspace/logs:/logs:ro           # JSONL logs (read-only)
      - /path/to/workspace/canvas:/canvas:ro       # Static pages (read-only)
    environment:
      - DB_PATH=/data/agent.db
      - LOGS_PATH=/logs
      - PORT=3000
    ports:
      - "3000:3000"
    networks:
      - agent-network

networks:
  agent-network:
    external: true
```

Key points:
- Mount workspace directories as **read-only** (`:ro`) — the dashboard should never modify agent data
- Use an external Docker network if you have other services (Traefik, databases)
- Set restart policy to `unless-stopped` for reliability

### Reverse Proxy (Traefik)

```yaml
# In your traefik dynamic config or docker labels
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.dashboard.rule=Host(`dashboard.yourdomain.com`)"
  - "traefik.http.routers.dashboard.tls=true"
  - "traefik.http.routers.dashboard.tls.certresolver=letsencrypt"
  - "traefik.http.routers.dashboard.middlewares=dashboard-auth"
  - "traefik.http.middlewares.dashboard-auth.basicauth.users=<HTPASSWD_STRING>"
```

### Authentication

At minimum, use HTTP Basic Auth. Your dashboard shows operational data — it shouldn't be public.

```bash
# Generate htpasswd string
htpasswd -nb yourusername yourpassword
# Output: yourusername:$apr1$...

# Use in Traefik config or nginx
```

For more sophisticated auth, consider:
- OAuth2 proxy (Google/GitHub login)
- Tailscale-only access (if you're on Tailscale)
- VPN-only access
- Client certificates

## Embedding Static Pages

Some content works better as pre-rendered HTML than dynamic dashboards:

```
canvas/
├── security-overview.html    # Security posture summary
├── architecture.html         # System architecture diagram
└── trading-report.html       # Generated trading analysis
```

Mount the `canvas/` directory and serve these as static pages within the dashboard. The agent can update these files via hooks or cron jobs.

## Building Your Dashboard

We deliberately don't share our dashboard code — it's tightly coupled to our specific setup. Instead, here's what to build:

### Option 1: Build From Scratch
- Pick a framework (Flask, Express, Next.js, Streamlit — whatever you know)
- Read SQLite directly (it's just a file, no server needed)
- Parse JSONL logs for cost and audit data
- Deploy in Docker

### Option 2: Use Existing Tools
- **Grafana** — great for metrics and logs, can read SQLite via plugins
- **Metabase** — easy SQL-based dashboards
- **Datasette** — instant web UI for SQLite databases

### Option 3: Minimal Approach
- A simple script that generates a static HTML report
- Run it via cron, serve the HTML via any web server
- Low maintenance, low cost

## What to Build

- [ ] Choose a dashboard approach (custom, Grafana, Datasette, or static)
- [ ] Set up Docker container with read-only access to workspace data
- [ ] Build Projects tab reading from tasks SQLite
- [ ] Build System tab reading from LLM observer logs
- [ ] Build Security tab reading from audit logs
- [ ] Configure reverse proxy with TLS and authentication
- [ ] Set up auto-rebuild on data changes (or periodic refresh)
- [ ] Create a `status-report` cron that updates system metrics for the dashboard

---

*Previous: [Chapter 7 — Scripts Toolkit](07-scripts-toolkit.md) | Next: [Chapter 9 — Config](09-config.md)*
