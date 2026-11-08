// Jarvis Neural-TTS: Piper-VITS-Modell lokal im Browser (onnxruntime-web, WASM, 1 Thread)
import * as ort from "./ort.js";
let sess = null;
const u = f => new URL("./" + f, import.meta.url).href;
self.onmessage = async ({ data }) => {
  const { id, type } = data;
  try {
    if (type === "init") {
      if (!sess) {
        const [w, m] = await Promise.all([fetch(u("ort.wasm")), fetch(u(data.model))]);
        if (!w.ok || !m.ok) throw new Error("Download fehlgeschlagen");
        ort.env.wasm.numThreads = 1; ort.env.wasm.proxy = false; ort.env.wasm.wasmPaths = { mjs: u("ort-glue.js"), wasm: u("ort.wasm") }; ort.env.wasm.wasmBinary = await w.arrayBuffer();
        sess = await ort.InferenceSession.create(new Uint8Array(await m.arrayBuffer()), { executionProviders: ["wasm"], graphOptimizationLevel: "all" });
      }
      self.postMessage({ id, ok: true });
    } else if (type === "run") {
      const ids = data.ids, n = ids.length;
      const feeds = {
        input: new ort.Tensor("int64", BigInt64Array.from(ids, BigInt), [1, n]),
        input_lengths: new ort.Tensor("int64", BigInt64Array.from([BigInt(n)]), [1]),
        scales: new ort.Tensor("float32", Float32Array.from(data.scales), [3])
      };
      const out = await sess.run(feeds), pcm = new Float32Array(out.output.data);
      self.postMessage({ id, pcm }, [pcm.buffer]);
    }
  } catch (e) { self.postMessage({ id, err: String(e && e.message || e) }); }
};
