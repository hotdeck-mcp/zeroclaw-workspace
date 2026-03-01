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
    if not "%BOCLAW_TOKEN%"=="" (
        curl -s -X POST "https://api.telegram.org/bot%BOCLAW_TOKEN%/sendMessage" ^
          -d "chat_id=6733341890&text=🤖 ZeroClaw is ONLINE%0A%0APublic URL: %NGROK_URL%%0ALocal: http://localhost:50001%0A%0AReady for tasks." > nul
        echo Notified BoClaw via Telegram.
    ) else (
        echo NOTE: Set BOCLAW_TOKEN env var to auto-notify BoClaw.
        echo       setx BOCLAW_TOKEN your_token_here
        echo       Current URL saved to C:\zeroclaw\zeroclaw-url.txt
    )
)

echo.
echo ZeroClaw is running. To stop: zeroclaw-stop.bat
pause
