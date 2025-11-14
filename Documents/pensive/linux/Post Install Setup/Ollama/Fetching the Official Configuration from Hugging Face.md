
Next, we'll trick Ollama into downloading just the configuration for the model you already have.

#### 1. Locate the Model on Hugging Face
Go to the model's page on Hugging Face (e.g., `unsloth/DeepSeek-R1-0528-Qwen3-8B-GGUF`). Navigate to the **"Files and versions"** tab to see all available quantization files.

#### 2. Get the Ollama Command
Find the exact GGUF file you downloaded (e.g., `Q4_K_M`) and *click that model gguf and when it takes you to the download page with just that one quantized file* . To the right of the file name, click **"Use this model"** and select **Ollama** from the dropdown. This will reveal the `ollama run` command.

> [!WARNING] Critical Step: Match the Quantization
> The URL provided by Hugging Face must correspond to the **exact quantization** of the file you already downloaded (e.g., `:Q4_K_M`). If you use the wrong one, Ollama will download the entire model again, defeating the purpose of this guide.

#### 3. Run the Command
Copy the command and run it in your terminal.
```bash
ollama run hf.co/unsloth/DeepSeek-R1-0528-Qwen3-8B-GGUF:Q4_K_M
```
Because Ollama detects that the required model blob (layer data) already exists from Phase 1, it will only download the manifest and configuration, which is very fast. This creates a *second* model entry with a long, repository-based name.