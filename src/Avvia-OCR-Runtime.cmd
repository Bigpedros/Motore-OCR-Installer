@echo off
setlocal
title Motore OCR Local Runtime
cd /d "%~dp0"
set "NODE_EXE="
where node >nul 2>&1 && set "NODE_EXE=node"
if not defined NODE_EXE if exist "%ProgramFiles%\nodejs\node.exe" set "NODE_EXE=%ProgramFiles%\nodejs\node.exe"
if not defined NODE_EXE (
  echo Node.js non trovato.
  echo Esegui di nuovo Motore-OCR-Local-Setup.exe.
  pause
  exit /b 1
)
start "Motore OCR Local Runtime" /min "%NODE_EXE%" "%~dp0runtime-server.mjs"
exit /b 0
