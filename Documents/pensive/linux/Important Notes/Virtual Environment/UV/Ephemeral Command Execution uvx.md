
`uvx` allows you to run a command with packages installed into a temporary, ephemeral environment that is automatically deleted afterward. This is perfect for running Python-based tools without polluting any of your environments.

```bash
# Run 'cowsay' without permanently installing it
uvx cowsay "Hello from a temporary environment!"

# Run 'ruff' linter on your project using a specific Python version
uvx --python 3.12 ruff check .
```

### ⚙️ System & Cache Management

These commands help you manage the `uv` installation and its global cache.

> [!TIP] What is the Cache?
> `uv` maintains a global cache of downloaded package wheels to speed up subsequent installations across all your projects. These commands help you manage that cache.

| Command | Description |
| :--- | :--- |
| `uv cache clean` | Clears the entire global package cache to reclaim disk space. |
| `uv cache prune` | A safer alternative that removes only old, unused entries from the cache. |
| `uv --version` | Displays the installed version of `uv`. |
| `uv --help` | Shows the main help message and lists all available commands. |
| `uv <command> --help` | Shows detailed help for a specific subcommand (e.g., `uv pip install --help`). |

