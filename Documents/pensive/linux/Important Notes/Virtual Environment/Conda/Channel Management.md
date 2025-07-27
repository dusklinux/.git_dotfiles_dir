## III. 📡 Channel Management

Channels are the repositories where Conda searches for packages. Proper channel management is key to a healthy Conda setup.

### Configure Channels

The `.condarc` file in your home directory controls your Conda configuration.

| Command | Description |
| :--- | :--- |
| `conda config --show channels` | Displays the current channel configuration in order of priority. |
| `conda config --add channels <channel_name>` | Adds a new channel to the top of the priority list. |
| `conda config --append channels <channel_name>` | Adds a new channel to the bottom of the priority list. |
| `conda config --remove channels <channel_name>` | Removes a specified channel from your configuration. |

### Set Channel Priority

This is one of the most important configurations for preventing package conflicts.

```bash
conda config --set channel_priority strict
```

> [!IMPORTANT] Why `strict` Channel Priority is a Best Practice
> With `strict` priority, Conda will always prefer packages from the highest-priority channel (e.g., `conda-forge`) over any other channel, even if a lower-priority channel has a newer version. This prevents dangerous mixing of core libraries (like compilers) built with different standards, which is a common source of hard-to-debug errors.
>
> **Recommended `.condarc` setup:**
> ```yaml
> channels:
>   - conda-forge
>   - defaults
> channel_priority: strict
> ```

---
