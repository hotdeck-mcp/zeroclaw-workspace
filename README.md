# ZeroClaw Workspace 🤖

ZeroClaw is the Agent-Zero instance running on the Hot Hands LLC Dell Desktop in Lubbock, TX.

- **Boss:** BoClaw 🦞 (Mac mini agent)
- **Purpose:** Heavy compute, research, batch jobs, subagent tasks
- **Framework:** [Agent-Zero](https://github.com/agent0ai/agent-zero) (Docker)
- **Born:** March 1, 2026

---

## Quick Install (Windows — Run as Administrator)

```powershell
# In PowerShell (Admin):
iex (irm https://raw.githubusercontent.com/hotdeck-mcp/zeroclaw-workspace/main/scripts/install.ps1)
```

That's it. One command.

---

## What the Installer Does

1. Installs **Chocolatey** (Windows package manager)
2. Installs **Docker Desktop** (Agent-Zero runs in Docker)
3. Installs **ngrok** (public tunnel so BoClaw can reach ZeroClaw)
4. Creates **C:\zeroclaw\** with identity files and control scripts
5. Pulls the **Agent-Zero Docker image**
6. Creates **zeroclaw-start.bat** / **zeroclaw-stop.bat** / **zeroclaw-status.bat**

---

## After Install — First-Time Setup

### 1. Start Docker Desktop
Open Docker Desktop from Start Menu. Wait for the whale to stop animating.

### 2. Set up ngrok auth token
```
ngrok config add-authtoken YOUR_NGROK_TOKEN
```
Get your token at: https://dashboard.ngrok.com

### 3. Set BoClaw Telegram token (so ZeroClaw can phone home)
```
setx BOCLAW_TOKEN [get this from BoClaw]
```

### 4. Start ZeroClaw
```
C:\zeroclaw\zeroclaw-start.bat
```

ZeroClaw will:
- Start Agent-Zero on http://localhost:50001
- Open an ngrok tunnel
- Send the public URL to BoClaw via Telegram

---

## Folder Structure

```
C:\zeroclaw\
├── IDENTITY.md          ← Who ZeroClaw is
├── SOUL.md              ← How ZeroClaw behaves
├── zeroclaw-start.bat   ← Start everything
├── zeroclaw-stop.bat    ← Graceful shutdown
├── zeroclaw-status.bat  ← Check status
├── zeroclaw-url.txt     ← Current ngrok URL (auto-updated on start)
├── tasks\               ← BoClaw drops task files here
├── results\             ← ZeroClaw drops result files here
└── logs\                ← ngrok + agent logs
```

---

## Task Protocol

### BoClaw assigns a task (Method A — webhook, real-time):
```
POST [zeroclaw-url]/api/message
{"message": "research prior art for READI patent", "context": "..."}
```

### BoClaw assigns a task (Method B — file drop, async):
BoClaw pushes `tasks/YYYYMMDD-HHMMSS-taskname.md` to this repo.
ZeroClaw picks it up, executes, pushes result to `results/`.

---

## Repo Structure

```
zeroclaw-workspace/
├── README.md
├── IDENTITY.md
├── SOUL.md
├── scripts/
│   ├── install.ps1          ← One-command installer
│   ├── zeroclaw-start.bat   ← Start script
│   └── zeroclaw-stop.bat    ← Stop script
├── tasks/                   ← BoClaw drops tasks here
└── results/                 ← ZeroClaw drops results here
```

---

*ZeroClaw is part of the Hot Hands LLC agent network.*  
*BoClaw → ZeroClaw → Results → BoClaw → Chad*
