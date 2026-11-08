# Jarvis Neural-Stimme (offline im Browser)

Piper-VITS-Stimme **Thorsten (de_DE, medium)**, dynamisch auf int8 quantisiert, läuft per
onnxruntime-web (WASM, 1 Thread) komplett im Browser – keine externen Dienste.

| Datei | Herkunft | Lizenz |
|---|---|---|
| `jarvis-de-model.wasm` | `rhasspy/piper-voices` → `de_DE-thorsten-medium.onnx`, int8 (`onnxruntime.quantization.quantize_dynamic`). Endung `.wasm` nur, weil der Artefakt-Server `.onnx` nicht ausliefert | CC0 (Thorsten Müller) |
| `jarvis-de.json` | gekürzte Modell-Konfiguration | CC0 |
| `ort.js`, `ort-glue.js`, `ort.wasm` | npm `onnxruntime-web@1.22.0` (`ort.wasm.bundle.min.mjs`, `ort-wasm-simd-threaded.mjs/.wasm`) | MIT |
| `phonemize-worker.js`, `piper_phonemize.wasm`, `piper_phonemize-data.wasm` | npm `piper-tts-web@1.1.2` (espeak-ng-Phonemizer); Worker so angepasst, dass mehrere Sätze zusammengeführt werden | MIT / espeak-ng: GPL-3.0 |
| `ort-worker.js` | eigener Inferenz-Worker | – |

Die Binärdateien liegen nicht im Repo (`.gitignore`). Neu erzeugen mit `./build.sh`.
