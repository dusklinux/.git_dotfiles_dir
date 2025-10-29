## 🚀 The Core Workflow: Your First `uv` Project

This section walks you through the most common, step-by-step process for starting a new project with `uv`.

### Step 1: Create and Enter Your Project Directory

Organization is key. Always start by creating a dedicated folder for your project.

```bash
mkdir my-new-project
cd my-new-project
```

### Step 2: Create the Virtual Environment

The `uv venv` command initializes a new, isolated Python environment. By default, it creates a hidden `.venv` directory, which is the standard convention.

```bash
uv venv
```

Or create a virtual environemtn with your own name for its directory (RECOMMANDED)
```bash
uv venv <myvirtualenv>
```

> [!TIP] Specifying a Python Version
> If you have multiple Python versions installed and need a specific one, use the `--python` flag.
> ```bash
> # Example: Create an environment with Python 3.11
> uv venv <myvirtualenv> --python 3.11
> ```

### Step 3: Activate the Environment

Activation configures your current shell session to use the environment's Python interpreter and its packages.

```bash
source <myvirtualenv>/bin/activate
```

Your shell prompt will now be prefixed with `<myvirtualenv>`, indicating the environment is active.

### Step 4: Install Packages

Use `uv pip install` to add packages to your active environment. It's incredibly fast.

```bash
# Install a single package
uv pip install requests

# Install multiple packages at once
uv pip install "fastapi[all]" uvicorn
```

### Step 5: Freeze Dependencies

To ensure your project is reproducible, save a list of all installed packages and their exact versions into a `requirements.txt` file.

```bash
uv pip freeze > requirements.txt
```

You can now share this `requirements.txt` file with others, and they can perfectly replicate your environment using `uv pip install -r requirements.txt`.
