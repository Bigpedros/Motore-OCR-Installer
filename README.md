# Motore OCR — Installer AI locale

Repository pubblico di distribuzione per il componente locale di **MOTORE OCR**.

Il repository principale del motore resta privato. Qui vengono pubblicati soltanto installer, runtime locale e script necessari a collegare la web app a:

- Ollama su `127.0.0.1:11434`
- OpenCode locale dedicato su `127.0.0.1:4098`
- OCR Local Runtime su `127.0.0.1:4097`

## Installazione

Usa sempre l'ultima release:

**Motore-OCR-Local-Setup.exe**

L'installer controlla ciò che è già presente e installa solo i componenti mancanti. Se Ollama è già installato, non viene reinstallato. Se è già disponibile almeno un modello compatibile, non ne scarica un altro.

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
