
This section covers the one-time setup for `pyenv` on an Arch Linux system.

### Step 1: Install Build Dependencies

`pyenv` builds Python versions from source, which requires a set of development tools and libraries. This command ensures all necessary build dependencies are installed.

```bash
sudo pacman -S --needed base-devel openssl zlib xz tk bzip2 readline sqlite3 ncurses
```

### Step 2: Install `pyenv`

We will use `paru` (or another AUR helper) to install `pyenv` from the Arch User Repository.

```bash
paru -S pyenv
```

### Step 3: Configure Your Shell for `pyenv`

For `pyenv` to work, it needs to be initialized every time you start your shell. This is done by adding configuration lines to your shell's startup file (e.g., `~/.zshrc` for Zsh or `~/.bashrc` for Bash).

Add the following lines to the very **end** of your `~/.zshrc` or `~/.bashrc` file:

```bash
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
```

> [!TIP] Understanding the Configuration
> - `export PYENV_ROOT`: Sets an environment variable to the location where `pyenv` stores Python versions.
> - `export PATH`: Adds the `pyenv` command-line utility to your system's `PATH`, so you can run `pyenv` commands.
> - `eval "$(pyenv init --path)"`: Injects `pyenv`'s shims directory into your `PATH`. Shims are lightweight executables that intercept calls to commands like `python` and `pip`.
> - `eval "$(pyenv init -)"`: Enables `pyenv`'s shell integration and autocompletion.

### Step 4: Regenerating Shims

> [!important]
> **Now regenerate Shims**
>```bash
>pyenv rehash
>```



### Step 5: Apply Changes

For the changes to take effect, you must **close and reopen your terminal** or run the following command:

```bash
# For Zsh users
source ~/.zshrc

# For Bash users
source ~/.bashrc
```

---
