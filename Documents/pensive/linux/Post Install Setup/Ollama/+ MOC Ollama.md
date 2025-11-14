
> [!important] Disable ollama service if you have nvidia gpu 
> leaving the service running keeps the gpu awake and there's no way to see what's using it. and you'll never know. this is fine if you're primarly using the nvidia gpu, in which case the nvidia gpu will always be awake anyway. but if you have a laptop with integrated gpu that puts the dedicated gpu to sleep. this will prevent 3d state for the nvidia gpu
# Manually Importing Local GGUF Models

This guide provides a detailed, step-by-step method for importing a pre-downloaded GGUF model into Ollama. The primary goal is to use your local model file while fetching the official `Modelfile` (containing parameters, templates, and system prompts) from Hugging Face. This process saves significant bandwidth by avoiding a redundant download and ensures your model runs with its intended configuration.

### Prerequisites

1.  **Ollama Installed:** The Ollama service must be installed and running on your system.
2.  **GGUF Model File:** You must have already downloaded the desired GGUF model file and know its location (e.g., `/mnt/media/models/qwen3-8b.gguf`).
3.  **User Permissions:** Your user account must be part of the `ollama` group to interact with the Ollama service without `sudo`. If you haven't done this, you can add your user with the command below and then **log out and log back in** for the change to take effect.
    ```bash
    sudo usermod -aG ollama your_username
    ```
    > [!NOTE] For more details on managing user groups, see [[User Group Assignments]].

---

## The Workflow at a Glance

The process involves four main phases:
1.  **Initial Import:** A "dummy" import to get the model data into Ollama's storage.
2.  **Fetch Configuration:** Downloading the official `Modelfile` from Hugging Face.
3.  **Extract & Refine:** Saving the official `Modelfile` and pointing it to your local GGUF file.
4.  **Final Import & Cleanup:** Removing the temporary models and creating the final, perfectly configured model.

---

> [!todo] Step 1
[[Initial Import of the GGUF Blob]]

> [!todo] Step 2
[[Fetching the Official Configuration from Hugging Face]]

> [!todo] Step 3
[[Extracting and Preparing the Perfect Modelfile]]

> [!todo] Step 3
[[Final Import and Cleanup]]


> [!tip] Custom Master Prompt
> [[Custom Prompting]]