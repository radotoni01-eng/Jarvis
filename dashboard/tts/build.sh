#!/usr/bin/env bash
# Erzeugt die Binärdateien der Neural-Stimme neu (braucht Zugriff auf huggingface.co und npm).
set -euo pipefail
cd "$(dirname "$0")"; T=$(mktemp -d)
curl -sSL -o "$T/m.onnx" https://huggingface.co/rhasspy/piper-voices/resolve/main/de/de_DE/thorsten/medium/de_DE-thorsten-medium.onnx
python3 -m venv "$T/v" && "$T/v/bin/pip" -q install onnx onnxruntime
"$T/v/bin/python" -c "from onnxruntime.quantization import quantize_dynamic, QuantType; quantize_dynamic('$T/m.onnx','jarvis-de-model.wasm', weight_type=QuantType.QUInt8)"
(cd "$T" && npm pack -q onnxruntime-web@1.22.0 piper-tts-web@1.1.2 >/dev/null && for f in *.tgz; do mkdir -p "${f%.tgz}" && tar xzf "$f" -C "${f%.tgz}"; done)
O="$T/onnxruntime-web-1.22.0/package/dist"; P="$T/piper-tts-web-1.1.2/package/dist"
cp "$O/ort.wasm.bundle.min.mjs" ort.js; cp "$O/ort-wasm-simd-threaded.mjs" ort-glue.js; cp "$O/ort-wasm-simd-threaded.wasm" ort.wasm
cp "$P/piper/piper_phonemize.wasm" piper_phonemize.wasm; cp "$P/piper/piper_phonemize.data" piper_phonemize-data.wasm
echo "Fertig. phonemize-worker.js ist bereits angepasst im Repo."
