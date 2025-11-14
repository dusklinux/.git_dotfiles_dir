
 Creating Custom Ollama Models

You can create your own custom Ollama models that remember a specific set of instructions for every conversation. This is perfect for creating specialized assistants that always behave a certain way, without you having to repeat the rules every time.

The whole process is done in the terminal using a special configuration file called a `Modelfile`.

### What is a `Modelfile`?

A `Modelfile` is a plain text file that acts like a recipe for building your custom model. It tells Ollama which base model to use and what permanent instructions to add.

There are two key commands you'll use inside it:

1.  **`FROM`**: Specifies the base model you want to customize. This can be any model you already have, like `llama3`, `codellama`, or `mistral`.
2.  **`SYSTEM`**: Sets the permanent instructions (the "system prompt") for your model. The model will follow these instructions at the start of every new chat.

---

### Step-by-Step Guide

Here’s how to create and use your own custom model.

#### Step 1: Create the `Modelfile`

First, create a new file named `Modelfile` using a text editor like `nvim`.

```bash
nvim Modelfile
```

Inside this file, you'll define your model. For this example, let's make a custom version of `llama3` that acts as a straight-to-the-point Arch Linux expert.

```modelfile
# 1. Specify the base model to build from
FROM llama3

# 2. Define the permanent system instructions
SYSTEM """
You are an Arch Linux expert. Your answers must be short and direct. Provide only commands and configurations. No chatter, no apologies. Just give clean, terminal-based solutions for Arch Linux.
"""
```

> [!TIP] Use Triple Quotes
> Using triple quotes `"""` lets you write multi-line instructions, which is great for more complex system prompts.

#### Step 2: Build Your Custom Model

With the `Modelfile` saved, use the `ollama create` command to build the new model. You need to give your new model a unique name (e.g., `arch-expert`).

```bash
ollama create arch-expert -f ./Modelfile
```

*   The `ollama create` command reads your `Modelfile`.
*   The `-f` flag points to the `Modelfile` you just created.
*   Ollama builds the new model and saves it locally.

#### Step 3: Use Your Custom Model

Your new model is now ready to use! Run it using its new name.

```bash
ollama run arch-expert
```

From now on, every time you run `arch-expert`, it will automatically follow the system prompt you defined in the `Modelfile`. You've successfully created your own specialized AI assistant


