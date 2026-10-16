@echo off
REM ================================================================
REM  Instalacion inicial de Chatwoot Community Edition (local)
REM  Ejecutar UNA sola vez. Para el dia a dia usar 2-iniciar.bat
REM ================================================================
cd /d "%~dp0"
title Instalando Chatwoot CE

if not exist ".env" (
  echo.
  echo  No hay archivo .env: generando uno nuevo con claves propias...
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\generar-env.ps1"
  if errorlevel 1 goto error
)

echo.
echo [1/4] Verificando Docker...
docker info >nul 2>&1
if errorlevel 1 (
  echo.
  echo  ERROR: Docker no esta instalado o Docker Desktop no esta abierto.
  echo  Abri Docker Desktop, espera a que diga "Engine running" y volve a ejecutar este archivo.
  echo  Descarga: https://www.docker.com/products/docker-desktop/
  echo.
  pause
  exit /b 1
)

echo.
echo [2/4] Descargando imagenes (la primera vez puede tardar varios minutos)...
docker compose pull
if errorlevel 1 goto error

echo.
echo [3/4] Preparando la base de datos...
docker compose up -d postgres redis
if errorlevel 1 goto error
timeout /t 10 /nobreak >nul
docker compose run --rm rails bundle exec rails db:chatwoot_prepare
if errorlevel 1 goto error

echo.
echo [4/4] Levantando Chatwoot...
docker compose up -d
if errorlevel 1 goto error

call "%~dp0esperar-chatwoot.bat"
exit /b %errorlevel%

:error
echo.
echo  Algo fallo. Revisa los mensajes de arriba.
pause
exit /b 1
