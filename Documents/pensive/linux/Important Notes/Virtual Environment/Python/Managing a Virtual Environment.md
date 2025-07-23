## 🌳 Managing Virtual Environment (`venv`)

The `venv` module is included with Python 3.3+ and is the standard way to create lightweight virtual environments.

### 1. Creating a New Environment

This command creates a new folder containing the Python interpreter, the standard library, and other supporting files.

```bash
python3 -m venv <environment-name>
```

*   `<environment-name>` is the name of the directory you want to create for your environment.

> [!TIP] Naming Convention
> A common convention is to name the environment directory `.venv`. The leading dot (`.`) makes the folder hidden on Unix-like systems, and many code editors (like VS Code) and tools are configured to automatically recognize and use a `.venv` directory.
>
> ```bash
> # Example: Create an environment named .venv in the current project directory
> python3 -m venv .venv
> ```

> [!NOTE] `python` vs `python3`
> Using `python3` is often safer than `python` to ensure you are using a Python 3 interpreter, as `python` can sometimes point to an older, system-installed Python 2 on some systems.

### 2. Activating the Environment

Activating an environment modifies your current shell session's `PATH` variable. This means that when you type `python` or `pip`, you are using the versions from your virtual environment, not the system-wide ones. The command differs based on your operating system and shell.

| Operating System | Shell | Command |
| :--- | :--- | :--- |
| Linux / macOS | Bash / Zsh | `source <environment-name>/bin/activate` |
| Linux / macOS | Fish | `source <environment-name>/bin/activate.fish` |
| Windows | Command Prompt | `<environment-name>\Scripts\activate.bat` |
| Windows | PowerShell | `<environment-name>\Scripts\Activate.ps1` |

> [!WARNING] PowerShell Execution Policy
> If you get an error running the `Activate.ps1` script on Windows, your Execution Policy may be too restrictive. You can allow scripts for the current session by running:
> `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process`

Once activated, your shell prompt will typically change to show the name of the active environment, like `(.venv) $`.

### 3. Deactivating the Environment

When you're finished working in the environment, you can deactivate it to return to your normal shell context.

```bash
deactivate
```

This command is only available when an environment is active. Your shell prompt will return to normal.

---
