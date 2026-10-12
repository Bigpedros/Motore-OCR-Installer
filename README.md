# Motore OCR — Installer AI locale

Repository pubblico di distribuzione per il componente locale di **MOTORE OCR**.

Il repository principale del motore resta privato. Qui vengono pubblicati soltanto installer, runtime locale e script necessari a collegare la web app a:

- Ollama su `127.0.0.1:11434`
- OpenCode locale dedicato su `127.0.0.1:4098`
- OCR Local Runtime su `127.0.0.1:4097`

## Installazione

Usa sempre la release **latest** e scarica:

**Motore-OCR-Local-Setup.exe**

Versione installer corrente: **0.1.1**.

L'installer controlla ciò che è già presente e installa solo i componenti mancanti tramite strumenti standard Windows (`winget`) e npm. Non usa più il precedente bootstrap PowerShell con `Invoke-Expression`.

Durante un aggiornamento chiude le precedenti istanze in ascolto sulle porte riservate 4097/4098, installa il runtime nuovo, lo riavvia e verifica automaticamente l'endpoint `/health`.

> Nota: il file EXE non è ancora firmato con certificato Authenticode. La firma digitale sarà necessaria per eliminare in modo affidabile gli avvisi di reputazione/SmartScreen su PC che non conoscono ancora l'applicazione.

## Modelli locali

Ordine di preferenza del runtime:

1. `qwen3:*`
2. `assistente-corso:*`
3. `llama3.2:3b`
4. altri `llama3.2:*`
5. primo modello Ollama disponibile

Se non è presente alcun modello compatibile, il setup scarica `qwen3:1.7B`.

## Privacy

La revisione AI prevista da MOTORE OCR utilizza il modello locale tramite Ollama. I documenti OCR non devono essere inviati a provider cloud per questa funzione.
