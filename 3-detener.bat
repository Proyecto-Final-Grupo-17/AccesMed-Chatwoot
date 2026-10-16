@echo off
REM Detiene Chatwoot. Los datos (cuentas, conversaciones, archivos) se conservan.
cd /d "%~dp0"
title Deteniendo Chatwoot CE
docker compose stop
echo.
echo  Chatwoot detenido. Tus datos quedan guardados.
pause
