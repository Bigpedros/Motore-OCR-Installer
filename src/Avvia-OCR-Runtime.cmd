@echo off
setlocal
cd /d "%~dp0"
set "NODE_EXE="
where node >nul 2>&1 && set "NODE_EXE=node"
if not defined NODE_EXE if exist "%ProgramFiles%\nodejs\node.exe" set "NODE_EXE=%ProgramFiles%\nodejs\node.exe"
if not defined NODE_EXE exit /b 1
start "" /b "%NODE_EXE%" "%~dp0runtime-server.mjs"
exit /b 0
