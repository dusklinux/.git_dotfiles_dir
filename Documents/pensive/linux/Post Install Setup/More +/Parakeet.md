```bash
paru -S sentencepiece
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
import nemo.collections.asr as nemo_asr
asr_model = nemo_asr.models.ASRModel.from_pretrained(model_name="nvidia/parakeet-tdt-0.6b-v2")
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