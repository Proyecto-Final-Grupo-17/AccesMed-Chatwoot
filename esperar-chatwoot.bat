@echo off
REM Espera a que Chatwoot responda en http://localhost:3000 y abre el navegador.
echo.
echo  Esperando a que Chatwoot responda en http://localhost:3000 ...
set /a intentos=0
:esperar
set /a intentos+=1
set CODIGO=
for /f %%c in ('curl.exe -s -o nul -w "%%{http_code}" http://localhost:3000/api') do set CODIGO=%%c
if "%CODIGO%"=="200" goto listo
if %intentos% GEQ 60 goto demora
timeout /t 5 /nobreak >nul
goto esperar

:listo
echo.
echo  ======================================================
echo   Chatwoot esta funcionando: http://localhost:3000
echo  ======================================================
start "" http://localhost:3000
pause
exit /b 0

:demora
echo.
echo  Chatwoot todavia no responde despues de 5 minutos.
echo  Ejecuta ver-logs.bat para ver que esta pasando.
pause
exit /b 1
