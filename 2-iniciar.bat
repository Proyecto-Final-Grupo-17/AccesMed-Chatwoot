@echo off
REM Inicia Chatwoot (despues de haber corrido 1-instalar.bat una vez)
cd /d "%~dp0"
title Iniciando Chatwoot CE
docker info >nul 2>&1
if errorlevel 1 (
  echo.
  echo  Docker Desktop no esta abierto. Abrilo, espera a que diga "Engine running" y reintenta.
  echo.
  pause
  exit /b 1
)
docker compose up -d
if errorlevel 1 (
  pause
  exit /b 1
)
call "%~dp0esperar-chatwoot.bat"
