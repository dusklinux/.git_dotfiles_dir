## 📚 Comprehensive Command Reference

This section serves as a detailed reference for all major `uv` commands, categorized by function.

### 🌳 Environment Management (`uv venv`)

These commands handle the creation and deletion of virtual environments.

| Command | Description |
| :--- | :--- |
| `uv venv` | Creates a virtual environment in the `./.venv` directory. |
| `uv venv <name>` | Creates a virtual environment in a directory with a specific `<name>`. |
| `uv venv --python <ver>` | Creates an environment using a specific Python version (e.g., `3.11` or `python3.11`). |
| `uv python find` | Lists all Python interpreters that `uv` can find on your system. |
| `source <env>/bin/activate` | **(Shell Command)** Activates the environment. |
| `deactivate` | **(Shell Command)** Deactivates the current environment. |

> [!WARNING] Deleting an Environment
> A virtual environment is just a directory. To delete it, you remove the directory itself. **This action is irreversible.**
> ```bash
> # Be absolutely sure you are in the correct parent directory!
> rm -rf <myvirtualenv>/
> ```
