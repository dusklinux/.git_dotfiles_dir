```bash
sudo pacman -S --needed --noconfirm mpv ffmpeg wl-clipboard mbuffer
```

```bash
paru -S --needed --noconfirm cuda-12.5 cudnn9.3-cuda12.5 
```

```bash
mkdir -p ~/contained_apps/uv/kokoro_gpu && cd ~/contained_apps/uv/kokoro_gpu
```

```bash
uv init -p 3.12 
```

```bash
uv add kokoro-onnx soundfile
```

```bash
uv pip install onnxruntime-gpu sounddevice
```

```bash
uv run python -m ensurepip --upgrade
uv run python -m pip install --upgrade pip setuptools wheel
```

this one command is usually not needed to be run.
```bash
uv run python -m pip install \
git+https://github.com/thewh1teagle/kokoro-onnx.git \
onnxruntime-gpu \
sounddevice
```

```bash
curl -L -o kokoro-v1.0.fp16-gpu.onnx \
https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/kokoro-v1.0.fp16-gpu.onnx
```

```bash
curl -L -o voices-v1.0.bin \
https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/voices-v1.0.bin
```

or  download both from gdrive (restricted link, only downloadable with storage from tim dillon)

```bash
https://drive.google.com/drive/folders/1pelrWJejLT-iyi__WXcqMYJgOYyvtaN8?usp=sharing
```

---

#### not needed to create this python script if you're using the keybind script. (skip this python script part )

```bash
nvim speak.py
```

> [!NOTE]- paste this text into it. 
> ```python
> import onnxruntime as ort
> from kokoro_onnx import Kokoro
> import sounddevice as sd
> 
> # 0. DEBUG: show providers on this Python process
> print("ONNX providers:", ort.get_available_providers())
> # Expect to see 'CUDAExecutionProvider' in that list.
> 
> # 1. Paths to model & voices
> MODEL_PATH  = "kokoro-v1.0.fp16-gpu.onnx"
> VOICES_PATH = "voices-v1.0.bin"
> 
> # 2. Initialize Kokoro (defaults to CPU session)
> kokoro = Kokoro(MODEL_PATH, VOICES_PATH)
> 
> # 3. Monkey-patch its session to use CUDA
> gpu_sess = ort.InferenceSession(
>     MODEL_PATH,
>     sess_options=ort.SessionOptions(),
>     providers=["CUDAExecutionProvider", "CPUExecutionProvider"]
> )
> kokoro.sess = gpu_sess
> 
> # 4. Your long text & simple splitting on sentences
> full_text = """
> Within the sepulchral confines of his atelier, a veritable catacomb of forgotten texts and anachronistic instruments, Dr. Alistair Finch, a jaded savant of some renown, found himself at a crossroads. His life’s work, a sprawling tome entitled The Abstruse Phenomenology of Auditory Nullification, was on the ropes. The deadline for its submission was nigh, yet the final chapter, a summation of his lifelong inquiry, remained a quagmire of untenable hypotheses and rhetorical sophistry. The crux of his argument—that silence was not merely the absence of sound but a palpable, active entity—felt as flimsy as a house of cards. He was, to put it plainly, spinning his wheels.
> 
> For years, he had been operating on the principle that the aural void possessed a structure, a negative space pregnant with potential, a concept that had, until this impasse, been the lodestar of his research. Now, it seemed nothing more than a fool’s errand, a tempest in a teapot. He felt he had bitten off more than he could chew, and the pressure was forcing him to bite the bullet and concede intellectual defeat. He had tried to get his ducks in a row, to consolidate his disparate findings, but the whole enterprise was a hot mess.
> 
> Leaving the intellectual battlefield, he ventured into the verdant, late-afternoon languor of his garden. He sat on a worn bench, a forgotten cigarette carton lying askew on the ground, and listened. Initially, all he heard was the absence he had so fetishized. But then, a subtle, almost imperceptible rustle of leaves, a whisper of wind through the tall grass, broke the oppressive stillness. Following on its heels was the strident, yet melodic, chirp of a solitary finch—a sound so unapologetically present, so unapologetically there, that it shattered his preconceived notions.
> 
> It was in that moment, in the wake of the finch's song, that the epiphany arrived, a bolt from the blue that knocked him for a loop. He had been looking at the problem ass-backwards. Silence was not an active entity; it was the context in which sound finds its meaning. The finch’s chirp was not a violation of silence, but its articulation. The sound gave the silence shape, scale, and dimension. The silence, in turn, imbued the chirp with its singular significance. It was a symbiotic relationship, a dialogue of presence and absence, a dialectical dance that gave the world its aural integrity. He had a brand new bag.
> 
> Invigorated, Dr. Finch hurried back to his study, a new fire in his belly. The final chapter was no longer a muddled thicket but a clear path. He had gotten a leg up on his own mental logjam. He would not simply conclude; he would illustrate. The finch’s song would be the fulcrum upon which his argument would turn, a simple yet profound illustration that would make his abstruse, doctoral-level discourse accessible to all. He was confident he could knock it out of the park.
> """
> chunks = [s.strip() + "." for s in full_text.split(".") if s.strip()]
> 
> # 5. Synthesize & play each chunk immediately
> for idx, chunk in enumerate(chunks, 1):
>     print(f"🔊 Synthesizing chunk {idx}/{len(chunks)}: {chunk}")
>     samples, sr = kokoro.create(
>         chunk,
>         voice="af_heart",
>         speed=1.0,
>         lang="en-us"
>     )
>     sd.play(samples, sr)
>     sd.wait()  # block until playback finishes
> 
> print("✅ All done!")
> ```

```bash
uv run python speak.py
```