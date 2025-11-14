### 📦 Package Management (`uv pip`)

These commands are used for installing, removing, and inspecting packages within an active environment.

#### Installation

| Command | Description |
| :--- | :--- |
| `uv pip install <pkg>` | Installs the latest version of a package. |
| `uv pip install <pkg>==<ver>` | Installs a specific version of a package (e.g., `numpy==1.26.2`). |
| `uv pip install --upgrade <pkg>` | Upgrades a package to the newest available version. |
| `uv pip install -r reqs.txt` | Installs all packages listed in a `requirements.txt` file. |
| `uv pip sync reqs.txt` | **Synchronizes** the environment to *exactly* match `requirements.txt`, adding missing packages and **removing** any that are not listed. |
| `uv pip install -e .` | Installs the project in the current directory in "editable" mode. |

> [!NOTE] `install` vs. `sync`
> - `uv pip install -r` is **additive**. It only installs or upgrades packages.
> - `uv pip sync` is **destructive**. It forces the environment to mirror the file, removing anything not present in `requirements.txt`. This is perfect for CI/CD or ensuring a clean state.

#### Inspection & Removal

| Command | Description |
| :--- | :--- |
| `uv pip list` | Lists all installed packages and their versions. |
| `uv pip freeze` | Lists installed packages in `requirements.txt` format. |
| `uv pip show <pkg>` | Displays detailed information about a specific package. |
| `uv pip check` | Verifies that all installed packages have compatible dependencies. |
| `uv pip uninstall <pkg>` | Removes a package from the environment. |

#### Offline & Local Installation

For air-gapped systems or using pre-downloaded wheels, you can point `uv` to a local directory.

```bash
# Example: Installing PyTorch from a local directory of wheel files
uv pip install torch torchvision torchaudio --no-index --find-links /path/to/local/wheels/
```
