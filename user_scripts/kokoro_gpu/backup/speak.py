#!/usr/bin/env python
import os
import onnxruntime as ort
from kokoro_onnx import Kokoro
import soundfile as sf
import sys
import io

# --- Configuration ---
# Adjust these paths if your models are located elsewhere.
MODEL_PATH = os.path.expanduser("~/contained_apps/uv/kokoro_gpu/kokoro-v1.0.fp16-gpu.onnx")
VOICES_PATH = os.path.expanduser("~/contained_apps/uv/kokoro_gpu/voices-v1.0.bin")

def initialize_kokoro():
    """Initializes and returns a CUDA-enabled Kokoro instance."""
    # print("DEBUG: Initializing Kokoro with ONNX providers:", ort.get_available_providers(), file=sys.stderr)
    try:
        kokoro = Kokoro(MODEL_PATH, VOICES_PATH)
        gpu_sess = ort.InferenceSession(
            MODEL_PATH,
            sess_options=ort.SessionOptions(),
            providers=["CUDAExecutionProvider", "CPUExecutionProvider"]
        )
        kokoro.sess = gpu_sess
        # print("DEBUG: Kokoro initialized with CUDA.", file=sys.stderr)
        return kokoro
    except Exception as e:
        print(f"FATAL: Failed to initialize Kokoro or CUDA session: {e}", file=sys.stderr)
        sys.exit(1)

def main():
    """
    Reads text from stdin, synthesizes it, and writes raw WAV audio to stdout.
    """
    # Read the full text from standard input.
    full_text = sys.stdin.read().strip()

    if not full_text:
        print("WARNING: No text provided via stdin. Exiting.", file=sys.stderr)
        sys.exit(0)

    kokoro = initialize_kokoro()

    # Synthesize the audio.
    # print(f"DEBUG: Synthesizing text: '{full_text[:50]}...'", file=sys.stderr)
    try:
        samples, sr = kokoro.create(
            full_text,
            voice="af_heart", # Or your preferred voice
            speed=1.0,      # kokoro playback speed
            lang="en-us"
        )
    except Exception as e:
        print(f"ERROR: Kokoro failed to synthesize audio: {e}", file=sys.stderr)
        sys.exit(1)

    # Use an in-memory buffer to write the WAV file.
    buffer = io.BytesIO()
    try:
        sf.write(buffer, samples, sr, format='WAV', subtype='PCM_16')
    except Exception as e:
        print(f"ERROR: Failed to write WAV data to buffer: {e}", file=sys.stderr)
        sys.exit(1)

    # Go to the beginning of the buffer and write its content to standard output.
    buffer.seek(0)
    sys.stdout.buffer.write(buffer.read())
    # print("DEBUG: Audio data written to stdout.", file=sys.stderr)

if __name__ == "__main__":
    main()
