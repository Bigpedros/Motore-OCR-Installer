$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$base = Join-Path $env:LOCALAPPDATA 'MotoreOCR'
$log = Join-Path $base 'install.log'
New-Item -ItemType Directory -Force -Path $base | Out-Null

function Log([string]$Text) {
  $line = "$(Get-Date -Format s) $Text"
  Add-Content -Path $log -Value $line
  Write-Host $Text
}

function Refresh-Path {
  $machine = [Environment]::GetEnvironmentVariable('Path','Machine')
  $user = [Environment]::GetEnvironmentVariable('Path','User')
  $env:Path = "$machine;$user;$env:APPDATA\npm"
}

function Has-Command([string]$Name) {
  return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

Log 'Avvio configurazione AI locale Motore OCR'
Refresh-Path

if (-not (Has-Command 'ollama')) {
  Log 'Ollama non trovato: avvio installazione ufficiale.'
  Invoke-RestMethod 'https://ollama.com/install.ps1' | Invoke-Expression
  Start-Sleep -Seconds 3
  Refresh-Path
} else {
  Log 'Ollama gia installato.'
}

if (-not (Has-Command 'node')) {
  Log 'Node.js non trovato: installazione LTS tramite winget.'
  if (-not (Has-Command 'winget')) { throw 'Node.js manca e winget non e disponibile.' }
  & winget install --id OpenJS.NodeJS.LTS -e --accept-source-agreements --accept-package-agreements
  Refresh-Path
}

if (-not (Has-Command 'opencode')) {
  Log 'OpenCode non trovato: installazione versione compatibile.'
  & npm install -g opencode-ai@1.19.0
  Refresh-Path
} else {
  Log 'OpenCode gia installato.'
}

if (-not (Has-Command 'ollama')) {
  $ollamaExe = Join-Path $env:LOCALAPPDATA 'Programs\Ollama\ollama.exe'
  if (Test-Path $ollamaExe) { Set-Alias ollama $ollamaExe } else { throw 'Ollama non disponibile dopo installazione.' }
}

try {
  $null = Invoke-RestMethod 'http://127.0.0.1:11434/api/tags' -TimeoutSec 5
} catch {
  $ollamaApp = Join-Path $env:LOCALAPPDATA 'Programs\Ollama\ollama app.exe'
  if (Test-Path $ollamaApp) { Start-Process $ollamaApp | Out-Null }
  Start-Sleep -Seconds 5
}

$models = @()
try {
  $tags = Invoke-RestMethod 'http://127.0.0.1:11434/api/tags' -TimeoutSec 10
  $models = @($tags.models | ForEach-Object { $_.name })
} catch {}

$compatible = $models | Where-Object { $_ -match '^qwen3:' -or $_ -match '^assistente-corso:' -or $_ -match '^llama3\.2:' }
if (-not $compatible) {
  Log 'Nessun modello compatibile trovato: scarico qwen3:1.7B.'
  & ollama pull qwen3:1.7B
} else {
  Log ("Modello locale gia disponibile: " + ($compatible -join ', '))
}

$runtime = Join-Path $env:LOCALAPPDATA 'MotoreOCR\Runtime\Avvia-OCR-Runtime.cmd'
if (Test-Path $runtime) {
  Log 'Avvio OCR Local Runtime.'
  Start-Process $runtime -WindowStyle Minimized
}
Log 'Configurazione completata.'
