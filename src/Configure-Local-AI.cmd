@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Motore OCR - Configurazione AI Locale

set "BASE=%LOCALAPPDATA%\MotoreOCR"
set "LOG=%BASE%\install.log"
if not exist "%BASE%" mkdir "%BASE%" >nul 2>&1

call :log "Avvio configurazione AI locale Motore OCR"

rem Chiude solo i processi che occupano le porte riservate al runtime Motore OCR.
call :killport 4097
call :killport 4098

set "PATH=%PATH%;%ProgramFiles%\nodejs;%APPDATA%\npm;%LOCALAPPDATA%\Programs\Ollama"

where winget >nul 2>&1
if errorlevel 1 (
  call :log "winget non disponibile: installazione automatica impossibile."
  echo.
  echo Installazione interrotta: Windows Package Manager ^(winget^) non disponibile.
  echo Installa App Installer dal Microsoft Store e rilancia il setup.
  exit /b 2
)

where ollama >nul 2>&1
if errorlevel 1 (
  if exist "%LOCALAPPDATA%\Programs\Ollama\ollama.exe" (
    set "OLLAMA_EXE=%LOCALAPPDATA%\Programs\Ollama\ollama.exe"
  ) else (
    call :log "Ollama non trovato: installazione tramite winget."
    winget install --id Ollama.Ollama -e --accept-source-agreements --accept-package-agreements --silent
    if errorlevel 1 exit /b 3
  )
)

set "PATH=%PATH%;%LOCALAPPDATA%\Programs\Ollama"
where ollama >nul 2>&1
if errorlevel 1 if exist "%LOCALAPPDATA%\Programs\Ollama\ollama.exe" set "OLLAMA_EXE=%LOCALAPPDATA%\Programs\Ollama\ollama.exe"
if not defined OLLAMA_EXE for /f "delims=" %%I in ('where ollama 2^>nul') do if not defined OLLAMA_EXE set "OLLAMA_EXE=%%I"

where node >nul 2>&1
if errorlevel 1 (
  call :log "Node.js non trovato: installazione LTS tramite winget."
  winget install --id OpenJS.NodeJS.LTS -e --accept-source-agreements --accept-package-agreements --silent
  if errorlevel 1 exit /b 4
)


rem Avvia Ollama solo se l'API non risponde.
curl.exe -fsS --max-time 3 http://127.0.0.1:11434/api/tags >nul 2>&1
if errorlevel 1 (
  if exist "%LOCALAPPDATA%\Programs\Ollama\ollama app.exe" (
    call :log "Avvio Ollama."
    start "" "%LOCALAPPDATA%\Programs\Ollama\ollama app.exe"
  ) else if defined OLLAMA_EXE (
    call :log "Avvio Ollama serve."
    start "Ollama" /min "%OLLAMA_EXE%" serve
  )
  timeout /t 5 /nobreak >nul
)

set "HAS_MODEL="
if defined OLLAMA_EXE (
  "%OLLAMA_EXE%" list 2>nul | findstr /I /C:"qwen3:" /C:"assistente-corso:" /C:"llama3.2:" >nul && set "HAS_MODEL=1"
)

if not defined HAS_MODEL (
  call :log "Nessun modello compatibile trovato: scarico qwen3:1.7B."
  "%OLLAMA_EXE%" pull qwen3:1.7B
  if errorlevel 1 exit /b 6
) else (
  call :log "Modello Ollama compatibile gia disponibile."
)

call :log "Avvio OCR Local Runtime aggiornato."
call "%~dp0Avvia-OCR-Runtime.cmd"
timeout /t 3 /nobreak >nul

curl.exe -fsS --max-time 5 http://127.0.0.1:4097/health > "%TEMP%\motore-ocr-health.json" 2>nul
if errorlevel 1 (
  call :log "Runtime non raggiungibile dopo l'installazione."
  exit /b 7
)

findstr /C:"\"runtimeVersion\":\"0.3.4\"" "%TEMP%\motore-ocr-health.json" >nul
if errorlevel 1 (
  call :log "Il runtime in ascolto non e la versione prevista."
  exit /b 8
)

call :log "Configurazione completata: Ollama + Runtime locale pronti."
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
