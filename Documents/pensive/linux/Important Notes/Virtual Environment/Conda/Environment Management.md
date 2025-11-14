## I. 🌳 Environment Management

These commands are the foundation of Conda, allowing you to create, isolate, and manage your project environments.

### Create a New Environment

This is the primary command for creating a new, isolated space for your projects.

```bash
conda create --name <env_name>
```

> [!TIP] Best Practice: Specify Python & Packages
> It's highly recommended to specify the Python version and core packages during creation. This ensures consistency and helps Conda's solver resolve dependencies more efficiently from the start.

**Common Usage:**

```bash
# Create an environment with a specific Python version
conda create --name data-science python=3.11

# Create an environment and install key packages simultaneously
conda create --name web-dev python=3.10 flask numpy pandas
```

### Activate & Deactivate Environments

Activating an environment modifies your shell's `PATH` to prioritize that environment's binaries.

| Command | Description |
| :--- | :--- |
| `conda activate <env_name>` | Activates the specified environment. Your shell prompt will change to `(<env_name>) ...` |
| `conda deactivate` | Deactivates the current environment, returning you to the `base` environment. |

> [!NOTE]
> The `(base)` environment is the default Conda environment. While you can install packages here, it is a best practice to create separate environments for each of your projects to avoid dependency conflicts.

### List All Environments

To see all the environments you have created on your system.

```bash
conda env list
# or the alias:
conda info --envs
```

The currently active environment will be marked with an asterisk (`*`).

### Clone an Environment

Create an exact, byte-for-byte replica of an existing environment. This is perfect for creating a stable "test" version of a "production" environment before making changes.

```bash
conda create --name <new_env_name> --clone <source_env_name>
```

**Example:**

```bash
# Clone the 'data-science' env to a new 'data-science-test' env
conda create --name data-science-test --clone data-science
```

### Remove an Environment

Completely delete an environment and all packages installed within it.

```bash
conda remove --name <env_name> --all
```

> [!WARNING] This Action is Irreversible
> The `--all` flag is crucial and ensures everything within the environment directory is deleted. There is no undo button, so use this command with caution.

### Run a Command Without Activating

Execute a command using an environment's interpreter without formally activating it. This is extremely useful for scripts and automation.

```bash
conda run -n <env_name> <command>
```

**Example:**

```bash
# Check the python version in the 'data-science' env without activating it
conda run -n data-science python --version
```

