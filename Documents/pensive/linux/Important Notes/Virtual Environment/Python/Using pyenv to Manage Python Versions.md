With `pyenv` installed, you can now easily download and switch between Python versions.

### Installing a Python Version

First, you need to install the desired Python version.

```bash
# Example: Install Python 3.11.5
pyenv install 3.11.5
```

> [!TIP] List Available Versions
> To see a complete list of all Python versions available to install (including CPython, PyPy, Anaconda, etc.), run:
> ```bash
> pyenv install --list
> ```

### Setting a Python Version

`pyenv` allows you to set Python versions at three different levels.

| Command | Scope | Description |
| :--- | :--- | :--- |
| `pyenv global <version>` | **Global** | Sets the default Python version for your user account. Used when no project-specific version is set. |
| `pyenv local <version>` | **Per-Project** | Sets the Python version for the current directory and its subdirectories. Creates a `.python-version` file. **This is the most common and recommended method for projects.** |
| `pyenv shell <version>` | **Current Shell** | Sets the Python version for the current terminal session only. Overrides `local` and `global`. |

### The Standard Workflow: `pyenv` + `venv`

This is the recommended process for starting a new project.

1.  **Navigate to your project directory:**
    ```bash
    mkdir ~/my-project && cd ~/my-project
    ```

2.  **Set the project-specific Python version with `pyenv`:**
    ```bash
    # This creates a .python-version file in your directory
    pyenv local 3.11.5
    ```

3.  **Create the virtual environment using `venv`:**
    Now, when you run `python`, `pyenv` ensures it's the version you just set (3.11.5).
    ```bash
    # Use the pyenv-controlled python to create the venv
    python -m venv <virtualenvironmentname>
    ```

4.  **Activate your new environment:**
    ```bash
    source <virtualenvironmentname>/bin/activate
    ```
    Your prompt will now show `(<virtualenvironmentname>)`, and you are running in an isolated environment using Python 3.11.5.
