# Chapter 11: Nodes

Nodes are companion devices — macOS, Android, or iOS — that connect to your OpenClaw instance and extend its capabilities beyond the server. This chapter is deliberately brief: the specifics depend entirely on your hardware.

## What Nodes Enable

When a companion device connects to your OpenClaw gateway, the agent gains access to:

| Capability | Description |
|-----------|-------------|
| **Browser automation** | Real Chrome/Safari via CDP (Chrome DevTools Protocol) — bypasses bot detection |
| **Camera** | Take photos via the device's camera |
| **Screen recording** | Capture what's on the device screen |
| **Location** | GPS coordinates from the device |
| **Notifications** | Push notifications to the device |
| **Canvas** | Present web content on the device display |
| **System commands** | Run AppleScript (macOS), shell commands on the device |
| **Audio** | Text-to-speech playback, microphone access |

## The Browser Profile System

The most valuable node capability is browser automation. Server-side headless browsers get blocked by Cloudflare, CAPTCHAs, and bot detection. A real Chrome instance on a Mac or PC doesn't.

### Profile Architecture

```
Browser Profiles:
├── openclaw (default)     — Headless Chromium on server. Fast, always available, gets bot-blocked.
├── node-browser           — Dedicated Chrome on a node device. Real browser, bypasses detection.
└── user-browser           — Human's actual browser. Last resort, requires manual attachment.
```

**Decision tree:**
1. No auth needed, simple page? → `openclaw` (headless, server-side)
2. Bot-blocked or needs authenticated session? → Node browser (real Chrome via CDP)
3. Needs the human's personal logged-in session? → Ask human to attach their browser

### CDP (Chrome DevTools Protocol) Tunnels

> **Warning:** CDP access is effectively remote control of a trusted browser session. Treat it like privileged access, because it is.

To use a node's browser from the server, you need a tunnel:

```
[Server] ←── SSH reverse tunnel ──→ [Node device running Chrome with --remote-debugging-port=9222]
```

The agent connects to `localhost:9222` on the server, which tunnels to the node's Chrome instance. This gives full browser automation capabilities — navigation, clicking, typing, screenshots, DOM inspection — all on a real browser that websites trust.

That power is exactly why you should keep it tightly scoped:
- use a dedicated browser profile, not the human's main browser
- restrict tunnel exposure to the server only
- prefer Tailscale or other private networking over public reachability
- assume anyone who gets CDP access effectively gets the browser session

### Persistent Browser Sessions

Node browsers maintain state across agent sessions:
- Cookies persist (stay logged into sites)
- Extensions work normally
- History and bookmarks available
- Separate Chrome profile directory (not the human's personal browser)

Log into services once manually, and the agent can use those sessions indefinitely.

## Node Pairing

OpenClaw companion apps handle the pairing process:

1. **Install the companion app** on your device (macOS, Android, or iOS)
2. **Generate a pairing code** from the OpenClaw gateway
3. **Enter the code** in the companion app
4. **Connection established** — the device appears as a node

For remote servers (VPS), you'll typically use Tailscale or SSH tunnels to establish connectivity between the node device and the gateway.

## Multi-Node Setup

You can connect multiple nodes for different purposes:

| Node | Purpose | Always On? |
|------|---------|-----------|
| Desktop/Laptop | Primary node — canvas, notifications, camera | When lid is open |
| Dedicated Mac Mini | 24/7 browser automation, transcription | ✅ Always |
| Phone (Android/iOS) | Location, on-the-go notifications | When carried |

### Node Selection Logic

When multiple nodes are available, the agent should prefer:
1. **The device the human is most likely using** for interactive things (canvas, notifications)
2. **The always-on device** for background tasks (browser automation, transcription)
3. **The phone** for location-aware or mobile tasks

Document your node preferences in TOOLS.md so the agent knows which device to use for what.

## What to Build

- [ ] Install the OpenClaw companion app on your primary device
- [ ] Pair at least one node to your gateway
- [ ] Set up a dedicated browser profile for agent automation (not your personal browser)
- [ ] Configure SSH tunnels for CDP access (if using a remote server)
- [ ] Document your nodes and their capabilities in TOOLS.md
- [ ] Define node selection preferences for your agent

---

*Previous: [Chapter 10 — Clones](10-clones.md) | Next: [Chapter 12 — A2A Comms](12-a2a-comms.md)*
