This section covers specialized `pip` commands for situations where you need to manage packages from a local directory, such as in an offline environment or for faster re-installations.

### Downloading Packages Locally

The `pip download` command fetches packages and their dependencies from a repository and saves them as wheel (`.whl`) files without installing them.

```bash
# Example: Download PyTorch and its dependencies to a local directory
pip download torch torchvision torchaudio --dest /mnt/zram1/local_whl_dir/
```

You can also specify versions:
```bash
# Download a specific version
pip download "Cython==3.0.5" --dest /path/to/dir

# Download a version within a range
pip download "numpy>=1.24,<1.26" --dest /path/to/dir
```

### Installing from a Local Source

Once you have a directory of wheel files, you can instruct `pip` to install from it.

```bash
pip install torch --find-links=/mnt/zram1/python_whl_local/
```

> [!WARNING] `--no-index` vs. `--find-links`
> - **Hybrid Mode (Recommended):** `pip install <pkg> --find-links /path/to/local/`
>   This tells `pip` to *first* look in your local directory. If a dependency is not found there, it will then search the default online repository (PyPI). This is flexible and robust.
> - **Offline Mode (Strict):** `pip install <pkg> --no-index --find-links /path/to/local/`
>   The `--no-index` flag **completely disables** access to online repositories like PyPI. The installation will fail if *any* package or sub-dependency is missing from your local directory. Use this only for truly offline installations.

### Clearing the `pip` Cache

`pip` maintains a cache of downloaded packages to speed up subsequent installations. If you suspect the cache is corrupted or want to free up disk space, you can clear it.

```bash
pip cache purge
```

> [!CAUTION]
> Running `pip cache purge` will delete all cached package files. The next time you install any of these packages, `pip` will need to re-download them from the internet.

