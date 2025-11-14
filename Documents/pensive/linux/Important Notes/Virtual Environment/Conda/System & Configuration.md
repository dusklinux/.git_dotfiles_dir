## V. ⚙️ System & Configuration

Commands for inspecting your Conda installation, managing its configuration, and cleaning up disk space.

### Get Conda Information

Display information about your Conda installation, including active environment, platform, and channel URLs.

```bash
conda info
```

### Clean Conda Caches

Conda caches package tarballs and metadata to speed up installations. Over time, this can consume a lot of disk space.

```bash
# Remove unused package tarballs and index cache
conda clean --all

# To be more specific:
conda clean --tarballs # Removes downloaded .tar.bz2 files
conda clean --packages # Removes unused cached package directories
```

> [!NOTE]
> Running `conda clean -a` is a safe and effective way to free up gigabytes of disk space without affecting your installed environments.

### Manage Conda Configuration

Directly view and modify settings in your `.condarc` file.

| Command | Description |
| :--- | :--- |
| `conda config --show` | Displays all configuration settings. |
| `conda config --get <key>` | Retrieves the value for a specific configuration key. |
| `conda config --set <key> <value>` | Sets a configuration key to a specific value (e.g., `boolean`, `string`). |

**Example:** Prevent the `base` environment from activating by default in new terminal sessions.

```bash
conda config --set auto_activate_base false
```
