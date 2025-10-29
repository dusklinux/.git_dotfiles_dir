# 🎨 `pywal16`: Installation and Setup on Arch Linux

This guide provides a clear, step-by-step process for installing and configuring `pywal16`, a backend for the popular theming tool `pywal`. We will use `pipx` to ensure a clean, isolated installation that won't interfere with system packages.

---

## ⚙️ Installation

Follow these steps to get `pywal16` up and running on your system.

### Step 1: Install `pipx`

`pipx` is a tool that allows you to install and run Python applications in isolated environments. It's the recommended way to install command-line tools like `pywal16`.

To install `pipx` on Arch Linux, use your package manager:

```bash
sudo pacman -S --needed python-pipx
```

> [!TIP] Why use `pipx`?
> `pipx` installs packages into their own virtual environments, preventing dependency conflicts with other Python projects or system-level packages. It also automatically adds the application's executable to your user path.

### Step 2: Install `pywal16`

With `pipx` installed, you can now install `pywal16` with a single command:

```bash
pipx install pywal16
```

---

## 🔧 Environment Configuration

For your shell to find and execute `pywal16`, you must ensure the `pipx` binary directory is included in your system's `PATH`.

### Step 3: Configure Your Shell's PATH

Add the following line to the end of your shell's configuration file (e.g., `~/.zshrc` for Zsh, `~/.bashrc` for Bash, or `~/.config/fish/config.fish` for Fish).

```bash
export PATH="$HOME/.local/bin:$PATH"
```

> [!NOTE] What does this do?
> This command tells your shell to look for executables in the `$HOME/.local/bin` directory, which is where `pipx` places the tools it installs. Adding it to your shell's startup file makes this change permanent for all new terminal sessions.

### Step 4: Apply the Changes

To make the changes take effect immediately in your current session, you must "source" your configuration file or simply close and reopen your terminal.

```bash
# For Zsh users
source ~/.zshrc

# For Bash users
source ~/.bashrc
```

---

## ✅ Verification and Usage

Finally, let's verify that the installation was successful and review how to use it.

### Step 5: Verify the Installation

You can confirm that `pywal16` is correctly installed and accessible by checking its help menu:

```bash
pywal16 --help
```

If this command displays the help information, the setup is complete!

### Basic Usage

`pywal16` is designed to be used as a backend for `wal`. To generate a 16-color theme from an image, you would run:

```bash
wal -i /path/to/your/image.jpg --backend pywal16
```

This will generate and apply a color scheme based on the provided image, using the `pywal16` logic.

