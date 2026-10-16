@echo off
REM Muestra el estado de los contenedores y los ultimos logs. Ctrl+C para salir.
cd /d "%~dp0"
title Logs de Chatwoot CE
docker compose ps
echo.
docker compose logs --tail 100 -f rails sidekiq
