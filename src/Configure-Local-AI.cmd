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

call :log "Avvio configurazione AI locale leggera Motore OCR"

rem Chiude solo le porte riservate a Motore OCR. La 4098 puo contenere la vecchia istanza OpenCode/Ollama bridge.
call :killport 4097
call :killport 4098

set "PATH=%PATH%;%ProgramFiles%\nodejs;%LOCALAPPDATA%\Microsoft\WinGet\Links"

where winget >nul 2>&1
if errorlevel 1 (
  call :log "winget non disponibile: installazione automatica impossibile."
  echo Installa App Installer dal Microsoft Store e rilancia il setup.
  exit /b 2
)

where node >nul 2>&1
if errorlevel 1 (
  call :log "Node.js non trovato: installazione LTS tramite winget."
  winget install --id OpenJS.NodeJS.LTS -e --accept-source-agreements --accept-package-agreements --silent
  if errorlevel 1 exit /b 3
)
set "PATH=%PATH%;%ProgramFiles%\nodejs;%LOCALAPPDATA%\Microsoft\WinGet\Links"

set "LLAMA_FOUND="
where llama-server >nul 2>&1 && set "LLAMA_FOUND=1"
if not defined LLAMA_FOUND where llama >nul 2>&1 && set "LLAMA_FOUND=1"
if not defined LLAMA_FOUND (
  call :log "llama.cpp non trovato: installazione tramite winget."
  winget install llama.cpp --accept-source-agreements --accept-package-agreements --silent
  if errorlevel 1 exit /b 4
)
set "PATH=%PATH%;%LOCALAPPDATA%\Microsoft\WinGet\Links"

set "LLAMA_CMD="
for /f "delims=" %%I in ('where llama-server 2^>nul') do if not defined LLAMA_CMD set "LLAMA_CMD=%%I"
if not defined LLAMA_CMD for /f "delims=" %%I in ('where llama 2^>nul') do if not defined LLAMA_CMD set "LLAMA_CMD=%%I"
if not defined LLAMA_CMD if exist "%LOCALAPPDATA%\Microsoft\WinGet\Links\llama-server.exe" set "LLAMA_CMD=%LOCALAPPDATA%\Microsoft\WinGet\Links\llama-server.exe"
if not defined LLAMA_CMD if exist "%LOCALAPPDATA%\Microsoft\WinGet\Links\llama.exe" set "LLAMA_CMD=%LOCALAPPDATA%\Microsoft\WinGet\Links\llama.exe"
if not defined LLAMA_CMD (
  call :log "llama.cpp installato ma comando llama/llama-server non trovato."
  exit /b 5
)
call :log "Comando llama.cpp rilevato: %LLAMA_CMD%"

if not exist "%MODEL_FILE%" (
  call :log "Scarico il modello Qwen2.5 0.5B Q4_K_M (~500 MB)."
  curl.exe -L --fail --retry 3 --retry-delay 2 -o "%MODEL_FILE%.download" "%MODEL_URL%"
  if errorlevel 1 (
    del /q "%MODEL_FILE%.download" >nul 2>&1
    call :log "Download modello non riuscito."
    exit /b 6
  )
  move /y "%MODEL_FILE%.download" "%MODEL_FILE%" >nul
) else (
  call :log "Modello locale gia presente."
)

call :log "Avvio OCR Local Runtime 0.3.5."
call "%~dp0Avvia-OCR-Runtime.cmd"
timeout /t 4 /nobreak >nul

curl.exe -fsS --max-time 8 http://127.0.0.1:4097/health > "%TEMP%\motore-ocr-health.json" 2>nul
if errorlevel 1 (
  call :log "Runtime non raggiungibile dopo l'installazione."
  exit /b 7
)

findstr /C:"\"runtimeVersion\":\"0.3.5\"" "%TEMP%\motore-ocr-health.json" >nul
if errorlevel 1 (
  call :log "Il runtime in ascolto non e la versione prevista."
  exit /b 8
)

findstr /C:"\"modelInstalled\":true" "%TEMP%\motore-ocr-health.json" >nul
if errorlevel 1 (
  call :log "Il modello AI locale non risulta disponibile."
  exit /b 9
)

call :log "Configurazione completata: llama.cpp + Qwen 0.5B + Runtime locale pronti."
exit /b 0

:killport
for /f "tokens=5" %%P in ('netstat -ano ^| findstr /R /C:":%~1 .*LISTENING"') do (
  if not "%%P"=="0" (
    call :log "Chiusura processo precedente sulla porta %~1, PID %%P."
    taskkill /PID %%P /F >nul 2>&1
  )
)
exit /b 0

:log
echo [%date% %time%] %~1>>"%LOG%"
echo %~1
exit /b 0
