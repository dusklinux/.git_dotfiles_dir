
# Setting Up Faster Whisper for Speech-to-Text

This guide provides a complete walkthrough for installing and configuring `faster-whisper`, a powerful and efficient speech-to-text library. The process uses `uv` to create an isolated Python environment, ensuring that dependencies do not conflict with your system.

> [!NOTE] Prerequisites
> You must have **Python 3.9 or greater** installed on your system.

---

## Part 1: Installation and Environment Setup

Follow these steps to prepare the environment and install the necessary packages.

### Step 1: Create a Workspace Directory

First, we'll create a dedicated directory for our isolated applications and navigate into it. This keeps your projects organized.

```bash
mkdir -p ~/contained_apps/uv/
cd ~/contained_apps/uv/
```

### Step 2: Create an Isolated Python Environment

Using a virtual environment is crucial for isolating project dependencies. We will use `uv` to create an environment named `fasterwhisper_cpu`.

```bash
uv venv fasterwhisper_cpu
```

### Step 3: Activate the Environment

To use the environment, you must activate it. This command modifies your current shell session to use the Python and packages installed within `fasterwhisper_cpu`.

```bash
source fasterwhisper_cpu/bin/activate
```

> [!TIP] Check Your Prompt
> After activation, your shell prompt should change to indicate that you are now inside the `(fasterwhisper_cpu)` environment.

### Step 4: Go into the newly created virtual envionment directory.
```bash
cd fasterwhisper_cpu
```

### Step 5: Install Faster Whisper

With the environment active, you can now install the `faster-whisper` package using `uv pip`.

```bash
uv pip install faster-whisper
```

---

## Part 2: Running Transcription

Once installed, you can transcribe audio using one of the following methods.

### Method 1: Manual Transcription via Python Script

This method involves directly running a Python configuration script.

> [!WARNING] Configuration Required
> Before running, you must edit your Python script (`config.py`).
> 1.  **Set User Variables**: Update the absolute paths for your virtual environment and the Python script itself.
> 2.  **Model Selection**: The script defaults to the `small.en` model. You can change this to another model if desired.
> 3.  **Audio Input**: The script is configured to look for an audio file at `/mnt/zram1/mic/1_mic.wav`. Ensure this file exists before running.

Execute the script with the following command:

```bash
python /path/to/the/config.py
```

### Method 2: Fully Automated Shell Script

For a streamlined workflow, a shell script (`faster_whisper_sst.sh`) is available to automate the entire process: recording audio, activating the Python environment, transcribing the audio, and copying the formatted text to your clipboard.

> [!IMPORTANT] Edit Script Parameters
> You **must** edit the user-defined parameters at the top of the `faster_whisper_sst.sh` script to match your system's paths and settings before running it.

Run the script from your terminal:

```bash
$HOME/user_scripts/tts_stt/faster_whisper/faster_whisper_sst.sh
```

> [!important] Running the script for the first time will take time cuz it needs to download the models. 


it'll downlaod the models at this location. 
```bash
cd ~/.cache/huggingface/hub
```