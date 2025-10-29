## II. 📦 Package Management

These commands are for finding, installing, and managing the software packages within your active environment.

### Search for a Package

Search the configured channels for available packages.

```bash
conda search <package_name>
```

**Advanced Searching:**

```bash
# Search for a specific version
conda search "numpy=1.21"

# Use wildcards to find related packages
conda search "beautifulsoup*"

# Get detailed information, including dependencies
conda search --info <package_name>
```

### Install Packages

Install one or more packages into the currently active environment.

```bash
conda install <package1> <package2>
```

**Common Usage:**

```bash
# Install a package with a specific version
conda install numpy=1.23.5

# Install a package from a specific channel (e.g., conda-forge)
conda install -c conda-forge beautifulsoup4
```

> [!TIP] Install Multiple Packages at Once
> When setting up an environment, install as many packages as possible in a single `conda install` command. This allows the dependency solver to see all constraints at once, leading to a more stable and coherent installation.
>
> `conda install numpy pandas matplotlib scikit-learn`

### List Installed Packages

View all packages, including their versions and channel of origin, in the current environment.

```bash
conda list
```

### Update Packages

Update packages to their latest compatible versions.

| Command | Description |
| :--- | :--- |
| `conda update <package_name>` | Updates a single specified package. |
| `conda update --all` | Attempts to update all packages in the current environment. |

> [!CAUTION] Use `conda update --all` with Care
> In complex environments, `conda update --all` can be very slow and may sometimes lead to a broken state if dependencies conflict. A safer, more reproducible approach is to export your environment to a file, edit the version numbers, and create a new environment from that file.

### Remove Packages

Uninstall one or more packages from the current environment.

```bash
conda remove <package_name>
```

> [!NOTE]
> `conda uninstall <package_name>` is an alias for the `remove` command and performs the exact same function. `conda remove` will also automatically remove any dependencies that are no longer required by other packages.

---
