> [!top] not recommanded ,use the other one instead 

# Real-Time Transcription Setup: faster-whisper (Intel 12700H Optimized)

## 1. System Dependencies (Arch Linux)

Since we are using `sounddevice` for audio capture, we need the PortAudio backend installed at the system level. We use `pacman` with the `--needed` flag to skip packages that are already up to date.

```
# Install PortAudio and git if missing, skipping if already installed
sudo pacman -S --needed portaudio git
```

## 2. Project Initialization (using `uv`)

We will create the **virtual environment** in your centralized container path, and the **script** in your user scripts path. We added **scipy** to handle audio resampling cleanly.

```
# 1. Create the specific venv for this project inside your centralized uv folder
mkdir -p ~/contained_apps/uv
uv venv ~/contained_apps/uv/rt-whisper

# 2. Activate the environment
source ~/contained_apps/uv/rt-whisper/bin/activate

# 3. Install dependencies into this environment
# faster-whisper: The inference engine
# sounddevice: Audio capture
# numpy: Array operations
# scipy: For high-quality resampling (48k -> 16k)
uv pip install faster-whisper sounddevice numpy scipy

# 4. Create your script directory
mkdir -p ~/user_scripts/faster_whisper/new_faster
```

## 3. The Real-Time Transcription Script

Create a file named `main.py` inside `~/user_scripts/faster_whisper/new_faster/`.

- **Fixed Blinking:** Uses ANSI escape codes (`\033[H`) to overwrite text in-place without clearing the whole terminal history.
    
- **Fixed Execution:** Added `#!/usr/bin/env python3` so you can run it directly if the venv is active.
    
- **No Disappearing Text:** On exit (`Ctrl+C`), it prints the final text one last time so you can copy it.
    
- **Session Log:** Saves the full 30s window to `session_dump.txt` on exit.
    

```
#!/usr/bin/env python3
import time
import queue
import sys
import numpy as np
import sounddevice as sd
from faster_whisper import WhisperModel
from scipy import signal
import os

# --- CONFIGURATION ---
MODEL_SIZE = "distil-small.en"
COMPUTE_TYPE = "int8"
DEVICE = "cpu"
WHISPER_SAMPLE_RATE = 16000    
# Increased to 30s (Whisper's native window) for better context
BUFFER_DURATION = 30   
UPDATE_INTERVAL = 0.5  

# --- STATE ---
audio_queue = queue.Queue()
running = True

def audio_callback(indata, frames, time, status):
    """Callback for sounddevice."""
    if status:
        print(status, flush=True)
    audio_queue.put(indata.copy())

def clear_screen():
    """
    Uses ANSI escape codes to move cursor to home and clear screen.
    Much faster than os.system('clear') and prevents blinking.
    """
    sys.stdout.write("\033[H\033[J")
    sys.stdout.flush()

def main():
    # Print initial info before clearing
    print(f"Loading {MODEL_SIZE} on {DEVICE}...")
    
    model = WhisperModel(
        MODEL_SIZE, 
        device=DEVICE, 
        compute_type=COMPUTE_TYPE, 
        cpu_threads=4,
        num_workers=1
    )
    
    # 1. Detect Hardware Capabilities
    try:
        device_info = sd.query_devices(kind='input')
        native_rate = int(device_info['default_samplerate'])
    except Exception:
        native_rate = 48000  # Fallback
    
    print(f"Microphone Rate: {native_rate}Hz | Target: {WHISPER_SAMPLE_RATE}Hz")
    print("Buffer: 30 seconds. Press Ctrl+C to save and quit.")
    time.sleep(1) # Give user a second to read
    
    # 2. Prepare Buffers
    buffer_len = int(WHISPER_SAMPLE_RATE * BUFFER_DURATION)
    audio_buffer = np.zeros(buffer_len, dtype=np.float32)
    
    # 3. Start Stream
    block_size_native = 1024 if native_rate > 32000 else 512
    stream = sd.InputStream(
        channels=1, 
        samplerate=native_rate, 
        callback=audio_callback, 
        blocksize=block_size_native
    )
    
    last_inference_time = time.time()
    final_text = ""
    
    try:
        with stream:
            while running:
                # --- PROCESS AUDIO QUEUE ---
                new_samples = []
                while not audio_queue.empty():
                    chunk = audio_queue.get()
                    new_samples.append(chunk.flatten())
                
                if new_samples:
                    raw_audio = np.concatenate(new_samples)
                    
                    # --- RESAMPLING ---
                    if native_rate != WHISPER_SAMPLE_RATE:
                        if native_rate == 48000:
                             processed_audio = raw_audio[::3]
                        elif native_rate == 32000:
                             processed_audio = raw_audio[::2]
                        else:
                            samples_target = int(len(raw_audio) * WHISPER_SAMPLE_RATE / native_rate)
                            processed_audio = signal.resample(raw_audio, samples_target)
                    else:
                        processed_audio = raw_audio

                    # --- UPDATE RING BUFFER ---
                    num_new = len(processed_audio)
                    if num_new > 0:
                        audio_buffer = np.roll(audio_buffer, -num_new)
                        audio_buffer[-num_new:] = processed_audio

                # --- RUN INFERENCE ---
                now = time.time()
                if now - last_inference_time > UPDATE_INTERVAL:
                    segments, info = model.transcribe(
                        audio_buffer, 
                        beam_size=1, 
                        language="en", 
                        condition_on_previous_text=False,
                        vad_filter=True,
                        vad_parameters=dict(min_silence_duration_ms=500)
                    )

                    # Store segments for display
                    current_segments = list(segments)
                    
                    # Fast Clear (No Flicker)
                    clear_screen()
                    
                    print(f"--- LIVE TRANSCRIPTION ({MODEL_SIZE}) ---")
                    print(f"Context: {BUFFER_DURATION}s | Rate: {native_rate}Hz\n")
                    
                    final_text = ""
                    for segment in current_segments:
                        print(segment.text)
                        final_text += segment.text + "\n"
                    
                    last_inference_time = now
                
                time.sleep(0.01)

    except KeyboardInterrupt:
        pass
    finally:
        # On Exit: Print everything one last time without clearing
        print("\n\n--- FINAL CAPTURE ---")
        print(final_text)
        print("---------------------")
        
        # Save to file
        with open("session_dump.txt", "w") as f:
            f.write(final_text)
        print(f"Saved last {BUFFER_DURATION}s to 'session_dump.txt'")

if __name__ == "__main__":
    main()
```

## 4. Running the Script

### Standard Command (Simplest)

Since your virtual environment is separate from the script, you run it by calling the specific python executable inside your venv. You do NOT need to run `source activate` with this method.

```
~/contained_apps/uv/rt-whisper/bin/python ~/user_scripts/tts_stt/faster_whisper/new_faster/main.py
```

### Advanced: CPU Pinning (Optional)

If you experience stuttering (audio cutting out) because the system moves the process to E-cores, you can add `taskset` to the front of the command above.

```
taskset -c 0-11 ~/contained_apps/uv/rt-whisper/bin/python ~/user_scripts/tts_stt/faster_whisper/new_faster/main.py
```

### Troubleshooting

- **Permissions:** If you see "Permission denied", run `chmod +x ~/user_scripts/faster_whisper/new_faster/main.py`.
    
- **Audio Device Error:** If you see `PortAudioError`, ensure no other heavy audio applications are blocking the microphone (though Linux usually handles sharing fine).