```bash
paru -S --needed sentencepiece
```

```bash
cd ~/contained_apps/uv && uv venv parakeet --python 3.12 && source parakeet/bin/activate
```

```bash
cd parakeet
```

```bash
uv pip install -U "nemo_toolkit["asr"]"
```

Only if numpy fails to install.
```bash
uv pip install numpy==1.26.4 --force-reinstall
```

this is for the server script. 
```bash
uv pip install Flask
```

```bash
nvim modeldownload.py
```

copy and paste this into the file 
```ini
import torch
import nemo.collections.asr as nemo_asr
import gc

# 1. Force the download and initial load to happen on the CPU (System RAM)
#    This bypasses the 4GB limit of your GPU during the heavy loading phase.
print("⏳ Loading model to CPU (this handles the memory spike)...")
asr_model = nemo_asr.models.ASRModel.from_pretrained(
    model_name="nvidia/parakeet-tdt-0.6b-v2",
    map_location=torch.device("cpu")
)

# 2. Switch to Half Precision (FP16)
#    A 0.6B model in standard FP32 is ~2.4GB. In FP16, it is ~1.2GB.
#    This is CRITICAL for a 3050 Ti (4GB VRAM) to leave room for Hyprland.
print("📉 Converting to Half Precision (FP16) to save VRAM...")
asr_model = asr_model.half()

# 3. Clean up system memory before the move
gc.collect()
torch.cuda.empty_cache()

# 4. Move the streamlined model to the GPU
print("🚀 Moving model to GPU...")
try:
    asr_model = asr_model.cuda()
    print("✅ Success! Model is on GPU and ready for inference.")
except torch.cuda.OutOfMemoryError:
    print("❌ Still Out of Memory. Please close other GPU-heavy apps (browsers, games).")
    exit(1)

# Example Inference to verify it works
# files = ["/path/to/your/audio.wav"]
# asr_model.transcribe(paths2audio_files=files)
```

```bash
python modeldownload.py
```


the following is not needed, just run the exisitng custom made script with the assigned keybind in hyprconfig. 

---

```bash
wget https://dldata-public.s3.us-east-2.amazonaws.com/2086-149220-0033.wav
```

```bash
nvim transcribe.py
```

copy and pate this into the file. 
```bash
import nemo.collections.asr as nemo_asr 

# This line will download the model if it's not already cached 
asr_model = nemo_asr.models.ASRModel.from_pretrained(model_name="nvidia/parakeet-tdt-0.6b-v2") 

# Now you can use the asr_model to transcribe 
output = asr_model.transcribe(['2086-149220-0033.wav']) 

# And print the transcribed text 
print(output[0].text) 
```

```bash
python transcribe.py
```