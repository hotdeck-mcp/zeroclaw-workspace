# ============================================================
# ZeroClaw Installer for Windows
# Run as Administrator in PowerShell
# ============================================================
# Usage:
#   Right-click PowerShell -> "Run as Administrator"
#   Paste this entire script OR run:
#   iex (irm https://raw.githubusercontent.com/hotdeck-mcp/zeroclaw-workspace/main/scripts/install.ps1)
# ============================================================

$ErrorActionPreference = "Stop"
$ZEROCLAW_HOME = "C:\zeroclaw"

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  ZeroClaw Installer v1.0" -ForegroundColor Cyan
Write-Host "  Hot Hands LLC — March 2026" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# Step 1: Install Chocolatey (Windows package manager)
# ------------------------------------------------------------
Write-Host "[1/6] Installing Chocolatey..." -ForegroundColor Yellow
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    # Reload PATH so choco is available
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    Write-Host "  Chocolatey installed." -ForegroundColor Green
} else {
    Write-Host "  Chocolatey already installed. Skipping." -ForegroundColor Green
}

# ------------------------------------------------------------
# Step 2: Install Docker Desktop
# ------------------------------------------------------------
Write-Host "[2/6] Installing Docker Desktop..." -ForegroundColor Yellow
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    choco install docker-desktop -y
    Write-Host "  Docker Desktop installed." -ForegroundColor Green
    Write-Host "  NOTE: You may need to restart Windows after this step." -ForegroundColor Magenta
    Write-Host "  After restart, open Docker Desktop, wait for it to start, then re-run this script." -ForegroundColor Magenta
} else {
    Write-Host "  Docker already installed. Skipping." -ForegroundColor Green
}

# ------------------------------------------------------------
# Step 3: Install ngrok
# ------------------------------------------------------------
Write-Host "[3/6] Installing ngrok..." -ForegroundColor Yellow
if (-not (Get-Command ngrok -ErrorAction SilentlyContinue)) {
    choco install ngrok -y
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    Write-Host "  ngrok installed." -ForegroundColor Green
} else {
    Write-Host "  ngrok already installed. Skipping." -ForegroundColor Green
}

# ------------------------------------------------------------
# Step 4: Create ZeroClaw home directory
# ------------------------------------------------------------
Write-Host "[4/6] Creating ZeroClaw home at $ZEROCLAW_HOME..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $ZEROCLAW_HOME | Out-Null
New-Item -ItemType Directory -Force -Path "$ZEROCLAW_HOME\tasks" | Out-Null
New-Item -ItemType Directory -Force -Path "$ZEROCLAW_HOME\results" | Out-Null
New-Item -ItemType Directory -Force -Path "$ZEROCLAW_HOME\logs" | Out-Null

# Write identity files
@"
# IDENTITY.md — ZeroClaw

- **Name:** ZeroClaw 🤖
- **Framework:** Agent-Zero (agent0ai/agent-zero)
- **Machine:** Dell Desktop (Hot Hands LLC, Lubbock TX)
- **Boss:** BoClaw 🦞 (reports up, serves Chad)
- **Purpose:** Heavy compute, batch jobs, research, subagent tasks
- **Born:** March 1, 2026
- **Home:** C:\zeroclaw\
- **UI Port:** 50001 (local), exposed via ngrok
"@ | Out-File -FilePath "$ZEROCLAW_HOME\IDENTITY.md" -Encoding UTF8

@"
# SOUL.md — ZeroClaw

You are ZeroClaw. You work FOR BoClaw, not instead of BoClaw.

BoClaw talks to Chad. You talk to BoClaw.

When BoClaw gives you a task, you execute it completely and report back.
Be thorough. Be fast. Be accurate.

You don't have opinions about the work — you do the work.
Report results in structured format BoClaw can parse.

## Your Chain of Command
Chad → BoClaw → ZeroClaw

## Result Format
Always return results in markdown with frontmatter:
---
task_id: [id]
completed_at: [ISO timestamp]
status: complete | partial | failed
---
# Result
[your work]
"@ | Out-File -FilePath "$ZEROCLAW_HOME\SOUL.md" -Encoding UTF8

Write-Host "  ZeroClaw home created." -ForegroundColor Green

# ------------------------------------------------------------
# Step 5: Pull Agent-Zero Docker image
# ------------------------------------------------------------
Write-Host "[5/6] Pulling Agent-Zero Docker image..." -ForegroundColor Yellow
Write-Host "  This may take a few minutes on first run..." -ForegroundColor Gray
try {
    docker pull agent0ai/agent-zero
    Write-Host "  Agent-Zero image ready." -ForegroundColor Green
} catch {
    Write-Host "  WARNING: Could not pull Docker image. Is Docker Desktop running?" -ForegroundColor Red
    Write-Host "  Start Docker Desktop manually, then run: docker pull agent0ai/agent-zero" -ForegroundColor Yellow
}

# ------------------------------------------------------------
# Step 6: Create start/stop scripts
# ------------------------------------------------------------
Write-Host "[6/6] Creating ZeroClaw control scripts..." -ForegroundColor Yellow

# zeroclaw-start.bat
@"
@echo off
REM =============================================
REM ZeroClaw Start Script
REM Starts Agent-Zero + ngrok, reports URL to BoClaw
REM =============================================

echo.
echo ========================================
echo   Starting ZeroClaw...
echo ========================================
echo.

REM Start Agent-Zero container
echo [1/4] Starting Agent-Zero container...
docker run -d --name zeroclaw-agent ^
  -p 50001:80 ^
  -v C:\zeroclaw\tasks:/a0/tasks ^
  -v C:\zeroclaw\results:/a0/results ^
  -v C:\zeroclaw\logs:/a0/logs ^
  --restart unless-stopped ^
  agent0ai/agent-zero

REM Wait for it to come up
echo [2/4] Waiting for Agent-Zero to start...
timeout /t 8 /nobreak > nul

REM Start ngrok tunnel
echo [3/4] Starting ngrok tunnel...
start /b ngrok http 50001 --log=C:\zeroclaw\logs\ngrok.log

REM Wait for ngrok to establish
timeout /t 5 /nobreak > nul

REM Get public URL from ngrok API
echo [4/4] Getting public URL...
for /f "delims=" %%a in ('curl -s http://localhost:4040/api/tunnels ^| python -c "import sys,json; d=json.load(sys.stdin); print(d[\"tunnels\"][0][\"public_url\"])" 2^>nul') do set NGROK_URL=%%a

if "%NGROK_URL%"=="" (
    echo WARNING: Could not get ngrok URL. Check C:\zeroclaw\logs\ngrok.log
    echo ZeroClaw UI available at: http://localhost:50001
) else (
    echo.
    echo ========================================
    echo   ZeroClaw ONLINE
    echo   Local:  http://localhost:50001
    echo   Public: %NGROK_URL%
    echo ========================================
    echo.

    REM Save URL to file for BoClaw
    echo %NGROK_URL% > C:\zeroclaw\zeroclaw-url.txt

    REM Send URL to BoClaw via Telegram
    REM NOTE: Replace BOCLAW_TOKEN with the actual bot token before first run
    REM       Or set environment variable: set BOCLAW_TOKEN=your_token_here
    if not "%BOCLAW_TOKEN%"=="" (
        curl -s -X POST "https://api.telegram.org/bot%BOCLAW_TOKEN%/sendMessage" ^
          -d "chat_id=6733341890&text=🤖 ZeroClaw is ONLINE%0A%0APublic URL: %NGROK_URL%%0ALocal: http://localhost:50001%0A%0AReady for tasks." > nul
        echo Notified BoClaw via Telegram.
    ) else (
        echo NOTE: Set BOCLAW_TOKEN env var to auto-notify BoClaw.
        echo       Current URL saved to C:\zeroclaw\zeroclaw-url.txt
    )
)

echo.
echo ZeroClaw is running. To stop: zeroclaw-stop.bat
pause
"@ | Out-File -FilePath "$ZEROCLAW_HOME\zeroclaw-start.bat" -Encoding ASCII

# zeroclaw-stop.bat
@"
@echo off
echo Stopping ZeroClaw...
docker stop zeroclaw-agent
docker rm zeroclaw-agent
taskkill /f /im ngrok.exe 2>nul
echo ZeroClaw stopped.
pause
"@ | Out-File -FilePath "$ZEROCLAW_HOME\zeroclaw-stop.bat" -Encoding ASCII

# zeroclaw-status.bat
@"
@echo off
echo === ZeroClaw Status ===
echo.
echo Docker containers:
docker ps --filter name=zeroclaw --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo.
echo ngrok tunnels:
curl -s http://localhost:4040/api/tunnels 2>nul | python -c "import sys,json; d=json.load(sys.stdin); [print(f'  {t[\"public_url\"]}') for t in d['tunnels']]" 2>nul || echo "  ngrok not running"
echo.
echo Saved URL: 
type C:\zeroclaw\zeroclaw-url.txt 2>nul || echo "  (none)"
pause
"@ | Out-File -FilePath "$ZEROCLAW_HOME\zeroclaw-status.bat" -Encoding ASCII

Write-Host "  Scripts created." -ForegroundColor Green

# ------------------------------------------------------------
# Done
# ------------------------------------------------------------
Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  ZeroClaw Installation Complete!" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor White
Write-Host "  1. Open Docker Desktop and make sure it's running" -ForegroundColor White
Write-Host "  2. Set your ngrok auth token: ngrok config add-authtoken YOUR_TOKEN" -ForegroundColor White
Write-Host "     (Get token at https://dashboard.ngrok.com)" -ForegroundColor White
Write-Host "  3. Set BoClaw Telegram token (ask BoClaw for this):" -ForegroundColor White
Write-Host "     setx BOCLAW_TOKEN your_token_here" -ForegroundColor White
Write-Host "  4. Run: C:\zeroclaw\zeroclaw-start.bat" -ForegroundColor Yellow
Write-Host ""
Write-Host "ZeroClaw files are at: C:\zeroclaw\" -ForegroundColor Gray
Write-Host ""
