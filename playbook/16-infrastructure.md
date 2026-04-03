# Chapter 16: Infrastructure & Networking

Your agent runs on a server. Its services — dashboard, A2A platform, webhooks, gateway — need to be reachable. This chapter covers the networking layer that ties everything together: reverse proxy, DNS, Docker networking, private access, and remote connectivity.

## Read This Before You Copy Anything

This chapter contains some of the sharpest knives in the whole playbook.

It includes patterns that are powerful **and** easy to misuse:
- public reverse proxies
- agent gateway exposure
- Docker socket access
- browser automation tunnels
- host↔container bridges

Treat these as **advanced patterns**, not starter defaults.

**Default stance:**
- keep admin surfaces private first
- prefer Tailscale / VPN / LAN over public exposure
- expose only the minimum routes you actually need
- if you're unsure, do less

## The Standard Pattern

Most OpenClaw deployments converge on the same architecture:

```
Internet
    │
    ▼
┌─────────────────────────────────────┐
│  Reverse Proxy (Traefik)            │
│  - TLS termination (Let's Encrypt)  │
│  - Wildcard certificate             │
│  - Route by subdomain               │
│  - Basic auth / IP allowlists       │
├─────────────────────────────────────┤
│  Docker Network (shared)            │
│  ┌──────────┐  ┌──────────┐        │
│  │ Dashboard │  │ A2A Comms│        │
│  │ :3000     │  │ :3000    │        │
│  └──────────┘  └──────────┘        │
│  ┌──────────┐  ┌──────────┐        │
│  │ Gateway   │  │ Webhook  │        │
│  │ :18789    │  │ Receiver │        │
│  └──────────┘  └──────────┘        │
└─────────────────────────────────────┘
    │
    ▼ (Tailscale / SSH tunnels)
┌──────────────┐
│  Node devices │
│  (Mac, phone) │
└──────────────┘
```

## Reverse Proxy: Traefik

Traefik is the standard choice because it auto-discovers Docker containers via labels — no manual config files per service.

### Why Traefik

- **Docker-native** — reads container labels, auto-generates routes
- **Auto-TLS** — Let's Encrypt certificates with automatic renewal
- **Wildcard certs** — one certificate covers `*.yourdomain.com`
- **Middleware** — basic auth, rate limiting, IP allowlists per route
- **Hot reload** — add a new service, Traefik picks it up without restart

### Traefik Setup (Docker Compose)

> **Warning:** Traefik often needs read access to the Docker socket for service discovery. That's common, but still sensitive. Treat any container with Docker socket access as high-trust infrastructure.

```yaml
# docker-compose.traefik.yml
version: "3.8"

services:
  traefik:
    image: traefik:v3.0
    restart: unless-stopped
    command:
      - "--api.dashboard=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--providers.docker.network=<YOUR_NETWORK>"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--entrypoints.web.http.redirections.entrypoint.to=websecure"
      - "--certificatesresolvers.letsencrypt.acme.email=<YOUR_EMAIL>"
      - "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json"
      - "--certificatesresolvers.letsencrypt.acme.dnschallenge=true"
      - "--certificatesresolvers.letsencrypt.acme.dnschallenge.provider=<YOUR_DNS_PROVIDER>"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - traefik-certs:/letsencrypt
    networks:
      - <YOUR_NETWORK>
    environment:
      # DNS provider credentials for wildcard cert
      # Example for DigitalOcean:
      - DO_AUTH_TOKEN=<YOUR_TOKEN>
      # Example for Cloudflare:
      # - CF_API_EMAIL=<YOUR_EMAIL>
      # - CF_DNS_API_TOKEN=<YOUR_TOKEN>

volumes:
  traefik-certs:

networks:
  <YOUR_NETWORK>:
    external: true
```

### DNS Challenge Providers

Wildcard certificates require DNS challenge validation. Common providers:

| DNS Provider | Traefik Provider Name | Required Env Vars |
|-------------|----------------------|-------------------|
| DigitalOcean | `digitalocean` | `DO_AUTH_TOKEN` |
| Cloudflare | `cloudflare` | `CF_DNS_API_TOKEN` |
| Route53 | `route53` | `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` |
| Namecheap | `namecheap` | `NAMECHEAP_API_USER`, `NAMECHEAP_API_KEY` |

Full list: [Traefik ACME DNS providers](https://doc.traefik.io/traefik/https/acme/#providers)

## The Wildcard Subdomain Pattern

Instead of managing ports and paths, use subdomains:

```
dashboard.yourdomain.com    → Dashboard container (:3000)
a2a.yourdomain.com          → A2A Comms platform (:3000)
gateway.yourdomain.com      → OpenClaw Gateway (:18789)
polymarket.yourdomain.com   → Polymarket dashboard (:3001)
```

> **Safer default:** keep the gateway private if you can. Public subdomains are fine for dashboards and webhook receivers with proper auth; the agent control plane deserves more caution.

Or use a playground subdomain for non-production services:

```
dashboard.playground.yourdomain.com
a2a.playground.yourdomain.com
```

### DNS Setup

1. **Create a wildcard A record** pointing to your server IP:
   ```
   *.yourdomain.com        A    <SERVER_IP>
   *.playground.yourdomain.com  A    <SERVER_IP>
   ```

2. **Or use a CNAME** if your server has a stable hostname:
   ```
   *.playground.yourdomain.com  CNAME  server.yourdomain.com
   ```

### Service Labels

Each Docker service gets Traefik labels that define its route:

```yaml
# Example: Dashboard
services:
  dashboard:
    image: your-dashboard:latest
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.dashboard.rule=Host(`dashboard.playground.yourdomain.com`)"
      - "traefik.http.routers.dashboard.entrypoints=websecure"
      - "traefik.http.routers.dashboard.tls=true"
      - "traefik.http.routers.dashboard.tls.certresolver=letsencrypt"
      - "traefik.http.routers.dashboard.tls.domains[0].main=yourdomain.com"
      - "traefik.http.routers.dashboard.tls.domains[0].sans=*.yourdomain.com,*.playground.yourdomain.com"
      # Authentication
      - "traefik.http.routers.dashboard.middlewares=dashboard-auth"
      - "traefik.http.middlewares.dashboard-auth.basicauth.users=<HTPASSWD_STRING>"
      # Internal port
      - "traefik.http.services.dashboard.loadbalancer.server.port=3000"
    networks:
      - <YOUR_NETWORK>
```

Generate htpasswd strings:
```bash
# Install htpasswd
apt-get install apache2-utils

# Generate (escape $ signs for Docker: double them)
htpasswd -nb admin yourpassword | sed 's/\$/\$\$/g'
```

## Docker Networking

### The Shared Network Pattern

All services that need to talk to each other — or be discovered by Traefik — share one external Docker network.

```bash
# Create it once
docker network create <YOUR_NETWORK>
```

Then reference it in every `docker-compose.yml`:

```yaml
networks:
  <YOUR_NETWORK>:
    external: true
```

### Why External Networks Matter

- **Inter-service communication** — containers on the same network can reach each other by service name
- **Traefik discovery** — Traefik only routes containers on its configured network
- **Isolation** — services NOT on the shared network are invisible to Traefik (intentional for internal-only services)

### Common Network Layout

```
Shared Network (<YOUR_NETWORK>)
├── traefik          (reverse proxy)
├── dashboard        (web UI)
├── a2a-comms        (A2A platform)
├── a2a-webhook-receiver
└── other web services...

Internal-Only (default bridge or dedicated network)
├── databases
├── redis
└── background workers
```

### Host-to-Container Communication

Sometimes the host (where OpenClaw gateway runs) needs to reach containers, or containers need to reach host services.

```
Container → Host:
  Use the Docker bridge gateway IP (typically 172.17.0.1 or 172.19.0.1)
  Find it: docker network inspect <YOUR_NETWORK> | grep Gateway

Host → Container:
  Use localhost:<published_port> if ports are published
  Or container IP on the Docker network
```

For services that need both directions (e.g., webhook receiver calling back to the gateway), you may need:
- A socat bridge service that relays traffic between Docker network and host loopback
- UFW rules allowing Docker subnet traffic on specific ports

## Tailscale

If you only adopt one idea from this chapter, make it this one: **private-first access wins**. Tailscale is usually the cleanest way to keep the dangerous surfaces off the public internet.

Tailscale provides a private mesh network between your devices — server, laptop, phone, companion Macs. No port forwarding, no firewall rules, just encrypted peer-to-peer connections.

### What Tailscale Enables

| Use Case | How |
|----------|-----|
| **Node connectivity** | Companion devices (Mac, phone) connect to gateway via Tailscale IP |
| **Private dashboard access** | Access dashboard without exposing it to the internet |
| **SSH without port 22** | `tailscale ssh` with identity-based auth |
| **Inter-clone communication** | Clones on different servers reach each other privately |
| **MagicDNS** | Access devices by name: `server.tailnet-name.ts.net` |

### Setup Pattern

```bash
# Install on server
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up --ssh

# Install on companion devices
# macOS: App Store or brew install tailscale
# iOS/Android: App Store / Play Store

# Verify connectivity
tailscale status
```

### Gateway Configuration for Tailscale

When nodes connect via Tailscale, the gateway's public URL should use the Tailscale IP or MagicDNS name:

```json
{
  "gateway": {
    "bind": "0.0.0.0:18789",
    "remote": {
      "url": "http://<TAILSCALE_IP>:18789"
    }
  }
}
```

Or if using MagicDNS:
```json
{
  "gateway": {
    "remote": {
      "url": "http://server.tailnet-name.ts.net:18789"
    }
  }
}
```

### Tailscale vs Public URL

You might need both:
- **Tailscale URL** for node pairing and private access
- **Public URL** (via Traefik) for webhooks that come from external services

Configure the gateway's `remote.url` based on your primary use case. If most access is via Tailscale, use the Tailscale URL. External webhooks can hit the public Traefik route.

## SSH Tunnels

For cases where Tailscale isn't available or you need specific port forwarding:

### Browser CDP Tunnels

Companion Macs running Chrome for browser automation need their CDP port accessible from the server:

```bash
# Reverse tunnel: server can reach Mac's Chrome CDP
ssh -R 9222:localhost:9222 user@server

# With autossh for persistence
autossh -M 0 -f -N -R 9222:localhost:9222 user@server \
  -o "ServerAliveInterval=30" -o "ServerAliveCountMax=3"
```

### Making Tunnels Persistent

Use launchd (macOS) or systemd (Linux) to auto-start tunnels:

```xml
<!-- macOS: ~/Library/LaunchAgents/com.openclaw.tunnel.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "...">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.openclaw.tunnel</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/autossh</string>
        <string>-M</string><string>0</string>
        <string>-N</string>
        <string>-R</string><string>9222:localhost:9222</string>
        <string>user@server</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardErrorPath</key>
    <string>/tmp/openclaw-tunnel.log</string>
</dict>
</plist>
```

Load with: `launchctl load ~/Library/LaunchAgents/com.openclaw.tunnel.plist`

## Gateway Exposure

The OpenClaw gateway needs to be reachable for:
- **Node pairing** — companion devices connect via WebSocket
- **Webhook callbacks** — external services POST to webhook endpoints
- **Remote access** — managing the agent from outside the server

### Options

| Method | Pros | Cons |
|--------|------|------|
| Traefik route (public) | Works from anywhere, TLS | Exposed to internet, needs auth |
| Tailscale only (private) | Zero exposure, encrypted | Requires Tailscale on all devices |
| Both | Maximum flexibility | Two URLs to manage |

### Traefik Route for Gateway

> **Warning:** This is an advanced pattern, not a baseline recommendation. Publicly routing the gateway increases the blast radius of any auth or config mistake. Prefer Tailscale-only access for the gateway when possible.

```yaml
# In your gateway docker-compose or as Traefik file config
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.gateway.rule=Host(`gateway.yourdomain.com`)"
  - "traefik.http.routers.gateway.entrypoints=websecure"
  - "traefik.http.routers.gateway.tls.certresolver=letsencrypt"
  - "traefik.http.services.gateway.loadbalancer.server.port=18789"
```

Note: The gateway is typically a host process (not Docker), so you'll need Traefik's file provider or a reverse proxy rule to reach `localhost:18789` from within Docker.

## Firewall (UFW)

```bash
# Essential ports
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP (Traefik redirect)
ufw allow 443/tcp   # HTTPS (Traefik)

# If using Tailscale — it manages its own firewall rules
# No additional UFW rules needed for Tailscale traffic

# Docker subnet access (if containers need to reach host services)
# Add to /etc/ufw/before.rules in the *filter section:
-A ufw-before-input -s 172.16.0.0/12 -p tcp --dport 18789 -j ACCEPT
```

### UFW + Docker Gotcha

Docker bypasses UFW by default (it manipulates iptables directly).

```bash
# /etc/docker/daemon.json
{
  "iptables": false
}
```

> **Danger:** do not cargo-cult this setting. Disabling Docker's iptables management changes how container networking works and can break a working host or accidentally weaken assumptions if you don't fully understand the replacement firewall path.

In many cases, using `ufw-docker` or explicit firewall rules is the safer move. Research this before applying.

## Putting It All Together

### Checklist for a New Server

1. **DNS** — Create wildcard A record pointing to server IP
2. **Docker** — Install Docker, create shared external network
3. **Traefik** — Deploy with wildcard cert config and DNS challenge
4. **Tailscale** — Install and authenticate on server
5. **UFW** — Configure firewall rules
6. **Gateway** — Set `remote.url` to Tailscale IP or public URL
7. **Services** — Deploy with Traefik labels for subdomain routing
8. **Verify** — Test each subdomain resolves and serves correctly

### Checklist for Adding a Service

1. Add Traefik labels to the service's `docker-compose.yml`
2. Ensure it's on the shared Docker network
3. Choose authentication method (basic auth, IP allowlist, or Tailscale-only)
4. Deploy: `docker compose up -d`
5. Verify: `curl -I https://service.playground.yourdomain.com`

### Security Considerations

- **Never expose the gateway casually** — it is the control plane for your agent
- **Use authentication everywhere** — basic auth at minimum, stronger where possible
- **Prefer Tailscale** for administrative access (dashboard, gateway)
- **Public access only where needed** — typically webhook receivers and user-facing dashboards
- **Rate limit public endpoints** — Traefik middleware or application-level
- **Monitor access logs** — Traefik logs show all incoming requests
- **Document what's public vs private** — ambiguity is where mistakes breed

---

*Previous: [Chapter 15 — Context Management](15-context-management.md)*
