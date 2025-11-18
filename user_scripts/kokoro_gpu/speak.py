#!/usr/bin/env python
import os
import sys
import re
import onnxruntime as ort
from kokoro_onnx import Kokoro
import numpy as np

# --- Configuration ---
MODEL_PATH = os.path.expanduser("~/contained_apps/uv/kokoro_gpu/kokoro-v1.0.fp16-gpu.onnx")
VOICES_PATH = os.path.expanduser("~/contained_apps/uv/kokoro_gpu/voices-v1.0.bin")
VOICE_NAME = "af_heart"
LANG_CODE = "en-us"

# --- STRICT WHITELIST CONFIGURATION ---
# Only characters inside this string will be spoken. Everything else is deleted.
# a-z A-Z : Alphabets
# 0-9     : Numbers (remove '0-9' if you don't want numbers read)
# \s      : Spaces/Newlines (REQUIRED to separate words)
# .,!?;:  : Punctuation (REQUIRED for the AI to know when to pause/breathe)
# '       : Apostrophe (REQUIRED for words like "don't" or "it's")
# -       : Hyphen (Useful for compound words)
# if you want to include a special charactor just add another back slash followed by the special charactor. 
ALLOWED_CHARS = r"a-zA-Z0-9\s\.\,\!\?\;\:\'\-\%"

def initialize_kokoro():
    if not os.path.exists(MODEL_PATH) or not os.path.exists(VOICES_PATH):
        print(f"FATAL: Model files not found at {MODEL_PATH}", file=sys.stderr)
        os._exit(1)

    try:
        sess_options = ort.SessionOptions()
        sess_options.log_severity_level = 3
        
        kokoro = Kokoro(MODEL_PATH, VOICES_PATH)
        
        gpu_sess = ort.InferenceSession(
            MODEL_PATH,
            sess_options=sess_options,
            providers=["CUDAExecutionProvider", "CPUExecutionProvider"]
        )
        kokoro.sess = gpu_sess
        return kokoro
    except Exception as e:
        print(f"FATAL: Failed to initialize Kokoro/CUDA: {e}", file=sys.stderr)
        os._exit(1)

def clean_text(text):
    """
    Sanitizes text using a Strict Whitelist approach.
    """
    # 1. Handle Markdown Links: [Text](URL) -> Text
    # We do this BEFORE whitelisting so we preserve the label.
    text = re.sub(r'\[([^\]]+)\]\([^)]+\)', r'\1', text)

    # 2. Handle Raw URLs: Replace with "Link" or remove entirely
    text = re.sub(r'http[s]?://\S+', 'Link', text)

    # 3. THE NUCLEAR OPTION: Whitelist Filter
    # Regex logic: Match any character that is NOT (^) in ALLOWED_CHARS
    # and replace it with a space.
    cleaning_pattern = f"[^{ALLOWED_CHARS}]"
    text = re.sub(cleaning_pattern, ' ', text)

    # 4. Collapse multiple spaces/newlines into single space
    text = ' '.join(text.split())
    
    return text.strip()

def smart_split(text):
    """
    Splits text by sentence endings while ignoring abbreviations.
    """
    # Regex checks for punctuation (.?!;:) NOT preceded by common abbreviations
    pattern = r'(?<!\bMr)(?<!\bMrs)(?<!\bMs)(?<!\bDr)(?<!\bJr)(?<!\bSr)(?<!\bProf)(?<!\bVol)(?<!\bNo)(?<!\bVs)(?<!\bEtc)\s*([.?!;:]+)\s+'
    
    chunks = re.split(pattern, text)
    
    sentences = []
    if len(chunks) == 1:
        return chunks

    for i in range(0, len(chunks) - 1, 2):
        sentence = chunks[i].strip()
        punctuation = chunks[i+1].strip()
        if sentence:
            sentences.append(f"{sentence}{punctuation}")
            
    if len(chunks) % 2 != 0:
        last_chunk = chunks[-1].strip()
        if last_chunk:
            sentences.append(last_chunk)

    return sentences

def main():
    try:
        full_text = sys.stdin.read().strip()
        if not full_text:
            os._exit(0)

        # --- CLEANUP STEP ---
        cleaned_text = clean_text(full_text)
        if not cleaned_text:
            # If cleanup removes everything (e.g. input was just emoji), exit
            os._exit(0)

        kokoro = initialize_kokoro()
        sentences = smart_split(cleaned_text)

        for sentence in sentences:
            audio, sr = kokoro.create(
                sentence,
                voice=VOICE_NAME,
                speed=1.0,
                lang=LANG_CODE
            )
            
            if audio is not None and len(audio) > 0:
                if audio.dtype != np.float32:
                    audio = audio.astype(np.float32)
                
                try:
                    sys.stdout.buffer.write(audio.tobytes())
                    sys.stdout.buffer.flush()
                except BrokenPipeError:
                    os._exit(0)
                    
    except Exception as e:
        # print(f"Error: {e}", file=sys.stderr) 
        os._exit(1)

    os._exit(0)

if __name__ == "__main__":
    main()
