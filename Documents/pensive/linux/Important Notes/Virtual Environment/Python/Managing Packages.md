## 📦 Managing Packages (`pip`)

`pip` is Python's package installer. When an environment is activated, `pip` will install packages into that environment only, keeping your global Python installation clean.

### The `requirements.txt` Workflow

The key to a reproducible environment is the `requirements.txt` file. This file lists all the packages and their exact versions needed for your project.

**Workflow:**
1.  **Freeze:** Capture all packages in your current environment and save them to a file.
2.  **Install:** Use that file on another machine (or in a new environment) to install the exact same dependencies.

#### **Step 1: Generating a `requirements.txt` File**

The `pip freeze` command outputs a list of all installed packages and their versions in a format perfect for a requirements file.

```bash
pip freeze > requirements.txt
```

A `requirements.txt` file will look like this:
```
certifi==2023.11.17
numpy==1.26.2
pandas==2.1.4
requests==2.31.0
```

> [!TIP]
> Commit your `requirements.txt` file to your version control system (e.g., Git). This allows collaborators to perfectly replicate your development environment.

#### **Step 2: Installing from a `requirements.txt` File**

To install all the packages listed in the file, use the `-r` (or `--requirement`) flag.

```bash
pip install -r requirements.txt
```

### `pip` Command Reference

Here is a quick reference for the most common `pip` commands. All commands should be run inside an **activated** virtual environment.

| Command | Description |
| :--- | :--- |
| `pip install <pkg>` | Installs the latest version of a package. |
| `pip install <pkg>==<ver>` | Installs a specific version of a package (e.g., `requests==2.28.0`). |
| `pip install --upgrade <pkg>` | Upgrades an installed package to its latest version. |
| `pip uninstall <pkg>` | Removes a package. It will ask for confirmation. |
| `pip list` | Lists all installed packages and their versions in a readable format. |
| `pip show <pkg>` | Displays detailed information about a package, including its dependencies. |
| `pip check` | Verifies that installed packages have compatible dependencies. |

### Detailed Command Explanations

#### Installing Packages
```bash
# Install the latest version of requests
pip install requests

# Install a specific version of Flask
pip install Flask==2.3.0

# Install a version that is at least 2.0 but less than 3.0
pip install "fastapi>=2.0,<3.0"
```

#### Uninstalling Packages
```bash
pip uninstall numpy
```
> [!TIP] To skip the confirmation prompt (`Proceed (y/n)?`), use the `-y` flag:
> `pip uninstall -y numpy`

#### Inspecting the Environment
```bash
# Get a simple list of installed packages
pip list

# Get detailed information about the 'pandas' package
pip show pandas
```
The output of `pip show` is very useful for debugging, as it shows you the package's location, its dependencies (`Requires`), and what other packages depend on it (`Required-by`).

#### For Local Development
If you are developing a Python package on your local machine, you can install it in "editable" mode using the `-e` flag. This creates a link to your source code, so any changes you make to your code are immediately reflected in the environment without needing to reinstall.

```bash
# Run this in your project's root directory (where setup.py or pyproject.toml is)
pip install -e .
```
