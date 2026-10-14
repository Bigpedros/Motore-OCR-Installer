@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Motore OCR - Configurazione AI Locale Leggera

set "BASE=%LOCALAPPDATA%\MotoreOCR"
set "MODEL_DIR=%BASE%\models"
set "MODEL_FILE=%MODEL_DIR%\qwen2.5-0.5b-instruct-q4_k_m.gguf"
set "MODEL_URL=https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf"
set "LOG=%BASE%\install.log"

if not exist "%BASE%" mkdir "%BASE%" >nul 2>&1
if not exist "%MODEL_DIR%" mkdir "%MODEL_DIR%" >nul 2>&1

call :stage 1 "Preparazione e verifica componenti"
call :log "Avvio configurazione AI locale leggera Motore OCR"

rem Chiude eventuali runtime precedenti sulle porte riservate.
call :killport 4097
call :killport 4098

set "PATH=%PATH%;%ProgramFiles%\nodejs;%LOCALAPPDATA%\Microsoft\WinGet\Links"

where winget >nul 2>&1
if errorlevel 1 (
  call :fail 2 "winget non disponibile. Installa App Installer dal Microsoft Store."
)

where node >nul 2>&1
if errorlevel 1 (
  call :log "Node.js non trovato: installazione LTS tramite winget."
  winget install --id OpenJS.NodeJS.LTS -e --accept-source-agreements --accept-package-agreements --silent
  if errorlevel 1 call :fail 3 "Installazione Node.js non riuscita."
)
set "PATH=%PATH%;%ProgramFiles%\nodejs;%LOCALAPPDATA%\Microsoft\WinGet\Links"

set "NODE_EXE="
for /f "delims=" %%I in ('where node 2^>nul') do if not defined NODE_EXE set "NODE_EXE=%%I"
if not defined NODE_EXE if exist "%ProgramFiles%\nodejs\node.exe" set "NODE_EXE=%ProgramFiles%\nodejs\node.exe"
if not defined NODE_EXE if exist "%LOCALAPPDATA%\Programs\nodejs\node.exe" set "NODE_EXE=%LOCALAPPDATA%\Programs\nodejs\node.exe"
if not defined NODE_EXE call :fail 3 "Node.js installato ma eseguibile non trovato."
>"%~dp0node-path.txt" echo %NODE_EXE%
call :log "Node.js rilevato: %NODE_EXE%"

call :stage 2 "Verifica runtime llama.cpp"
set "LLAMA_FOUND="
where llama-server >nul 2>&1 && set "LLAMA_FOUND=1"
if not defined LLAMA_FOUND where llama >nul 2>&1 && set "LLAMA_FOUND=1"
if not defined LLAMA_FOUND (
  call :log "llama.cpp non trovato: installazione tramite winget."
  winget install llama.cpp --accept-source-agreements --accept-package-agreements --silent
  if errorlevel 1 call :fail 4 "Installazione llama.cpp non riuscita."
)
set "PATH=%PATH%;%LOCALAPPDATA%\Microsoft\WinGet\Links"

set "LLAMA_CMD="
for /f "delims=" %%I in ('where llama-server 2^>nul') do if not defined LLAMA_CMD set "LLAMA_CMD=%%I"
if not defined LLAMA_CMD for /f "delims=" %%I in ('where llama 2^>nul') do if not defined LLAMA_CMD set "LLAMA_CMD=%%I"
if not defined LLAMA_CMD if exist "%LOCALAPPDATA%\Microsoft\WinGet\Links\llama-server.exe" set "LLAMA_CMD=%LOCALAPPDATA%\Microsoft\WinGet\Links\llama-server.exe"
if not defined LLAMA_CMD if exist "%LOCALAPPDATA%\Microsoft\WinGet\Links\llama.exe" set "LLAMA_CMD=%LOCALAPPDATA%\Microsoft\WinGet\Links\llama.exe"
if not defined LLAMA_CMD if exist "%LOCALAPPDATA%\Microsoft\WinGet\Packages" (
  for /r "%LOCALAPPDATA%\Microsoft\WinGet\Packages" %%I in (llama-server.exe) do if not defined LLAMA_CMD set "LLAMA_CMD=%%I"
)
if not defined LLAMA_CMD if exist "%LOCALAPPDATA%\Microsoft\WinGet\Packages" (
  for /r "%LOCALAPPDATA%\Microsoft\WinGet\Packages" %%I in (llama.exe) do if not defined LLAMA_CMD set "LLAMA_CMD=%%I"
)
if not defined LLAMA_CMD call :fail 5 "llama.cpp installato ma eseguibile non trovato."
call :log "Comando llama.cpp rilevato: %LLAMA_CMD%"

call :stage 3 "Download modello Qwen2.5 0.5B"
if not exist "%MODEL_FILE%" (
  call :log "Scarico il modello Qwen2.5 0.5B Q4_K_M (~500 MB)."
  echo.
  echo NON CHIUDERE QUESTA FINESTRA.
  echo.
  curl.exe -L --fail --retry 3 --retry-delay 2 --progress-bar -o "%MODEL_FILE%.download" "%MODEL_URL%"
  if errorlevel 1 (
    del /q "%MODEL_FILE%.download" >nul 2>&1
    call :fail 6 "Download modello non riuscito."
  )
  move /y "%MODEL_FILE%.download" "%MODEL_FILE%" >nul
) else (
  call :log "Modello locale gia presente."
)

call :stage 4 "Verifica finale installazione"
call :log "Configurazione completata: runtime 0.4.0 + llama.cpp + Qwen 0.5B installati."

if not exist "%~dp0Avvia-OCR-Runtime-Nascosto.vbs" call :fail 7 "Launcher manuale AI non trovato."
if not exist "%~dp0runtime-server.mjs" call :fail 8 "Runtime locale non trovato."
if not exist "%MODEL_FILE%" call :fail 9 "Il modello AI locale non risulta disponibile."

echo.
echo [####################] 100%%
echo AI LOCALE INSTALLATA.
echo.
echo Avvio automatico disabilitato.
echo Per attivare il runtime usa il collegamento:
echo   "Avvia AI Motore OCR"
echo creato sul Desktop oppure nel menu Start.
echo.
echo Dopo l'avvio, OCR Lab raggiungera il bridge su:
echo   http://127.0.0.1:4097
echo.
call :log "Installazione pronta per avvio manuale tramite collegamento Desktop/Menu Start."
exit /b 0

:stage
cls
echo ============================================================
echo          MOTORE OCR - AI LOCALE LEGGERA
echo ============================================================
echo.
if "%~1"=="1" echo [#####---------------] 25%%  Fase 1 di 4
if "%~1"=="2" echo [##########----------] 50%%  Fase 2 di 4
if "%~1"=="3" echo [###############-----] 75%%  Fase 3 di 4
if "%~1"=="4" echo [##################--] 90%%  Fase 4 di 4
echo.
echo %~2
echo.
echo NON CHIUDERE QUESTA FINESTRA DURANTE LA CONFIGURAZIONE.
echo ============================================================
echo.
exit /b 0

:killport
for /f "tokens=5" %%P in ('netstat -ano ^| findstr /R /C:":%~1 .*LISTENING"') do (
  if not "%%P"=="0" (
    call :log "Chiusura processo precedente sulla porta %~1, PID %%P."
    taskkill /PID %%P /F >nul 2>&1
  )
)
exit /b 0

:fail
call :log "ERRORE %~1: %~2"
echo.
echo ERRORE: %~2
echo Log: %LOG%
echo.
pause
exit /b %~1

:log
echo [%date% %time%] %~1>>"%LOG%"
echo %~1
exit /b 0
