# Motore OCR — Installer AI locale leggera

Repository pubblico di distribuzione per il componente locale opzionale di **MOTORE OCR**.

Il repository principale resta privato. L'AI locale non è necessaria per l'OCR deterministico: serve soltanto come revisore manuale e leggero.

## Componenti

- OCR Local Runtime su `127.0.0.1:4097`
- `llama-server` (llama.cpp) su `127.0.0.1:4098`
- modello `Qwen2.5-0.5B-Instruct-GGUF Q4_K_M` in `%LOCALAPPDATA%\MotoreOCR\models`

**Ollama e OpenCode non fanno più parte del percorso Motore OCR.**

## Installazione

Scarica sempre la release **latest**:

**Motore-OCR-Local-Setup.exe**

Versione installer corrente: **0.1.5**.

Il setup usa `winget` per Node.js e llama.cpp quando mancanti e scarica una sola volta il modello GGUF (~500 MB). Supporta sia il vecchio eseguibile `llama-server` sia il comando recente `llama serve`, anche quando WinGet non espone subito il comando nel PATH: il runtime cerca direttamente nelle cartelle pacchetto WinGet. Dopo l'installazione la revisione AI funziona offline.

Durante l'aggiornamento vengono chiuse le vecchie istanze sulle porte 4097/4098, quindi anche un eventuale vecchio bridge OpenCode non resta attivo.

## Profilo risorse

La configurazione runtime è volutamente limitata:

- 2 thread CPU
- contesto 1536 token
- una sola richiesta alla volta
- output AI massimo 220 token
- timeout di revisione 16 secondi
- modello 0.5B quantizzato

L'OCR deterministico continua a funzionare anche se l'AI locale non è installata o non viene avviata.

## Privacy

Documenti e revisione rimangono sul PC. La connessione Internet serve soltanto per installazione/aggiornamento e per il download iniziale del modello. Dopo il download il runtime può funzionare offline.

> Nota: l'EXE non è ancora firmato con certificato Authenticode; Windows può quindi mostrare avvisi di reputazione/SmartScreen.


In caso di errore il configuratore lascia visibile il messaggio e indica il log persistente in `%LOCALAPPDATA%\MotoreOCR\install.log`.
