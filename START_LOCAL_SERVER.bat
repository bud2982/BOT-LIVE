@echo off
echo ========================================
echo 🚀 AVVIO SERVER PROXY LOCALE
echo ========================================
echo.

cd /d "c:\Users\Dario\Documents\GitHub\BOT LIVE\BOT-LIVE"

echo 📦 Installazione dipendenze...
call npm install

echo.
echo 🔥 Avvio server su http://localhost:3001
echo.
echo ⚠️  Premi CTRL+C per fermare il server
echo.

node proxy_server_new.js

pause