@echo off
echo ========================================
echo   Connection Diagnostic Tool
echo ========================================
echo.

echo [1/5] Checking if server is running...
tasklist /FI "IMAGENAME eq node.exe" 2>NUL | find /I /N "node.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo ✅ Node.js is running
) else (
    echo ❌ Node.js is NOT running
    echo    Start server with: cd server ^&^& npm start
    goto :end
)
echo.

echo [2/5] Checking port 5000...
netstat -ano | findstr ":5000" >NUL
if "%ERRORLEVEL%"=="0" (
    echo ✅ Port 5000 is listening
) else (
    echo ❌ Port 5000 is NOT listening
    goto :end
)
echo.

echo [3/5] Your computer's WiFi network:
netsh wlan show interfaces | findstr "SSID"
echo.
echo ⚠️  Make sure your PHONE is on the SAME WiFi!
echo.

echo [4/5] Your computer's IP address:
ipconfig | findstr "IPv4"
echo.

echo [5/5] Testing server locally...
curl -s http://192.168.1.5:5000 >NUL 2>&1
if "%ERRORLEVEL%"=="0" (
    echo ✅ Server is responding
) else (
    echo ❌ Server is NOT responding
)
echo.

echo ========================================
echo   Next Steps:
echo ========================================
echo.
echo 1. Make sure your phone WiFi matches above
echo 2. Open phone browser and visit:
echo    http://192.168.1.5:5000
echo.
echo 3. You should see: {"message":"Route not found"}
echo.
echo If you see that message, server is reachable!
echo If not, see: 🔧_CONNECTION_TROUBLESHOOTING.md
echo.

:end
pause
