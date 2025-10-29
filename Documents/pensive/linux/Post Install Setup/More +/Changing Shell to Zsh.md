# 🚀 Upgrading Your Shell: A Guide to Zsh on Arch Linux

Zsh (the Z shell) is a powerful and highly customizable alternative to the default Bash shell. This guide will walk you through installing Zsh, enhancing it with essential plugins and a modern prompt, and making it your default shell on Arch Linux.

---

## Step 1: Install Zsh and Essential Tools

First, we'll install Zsh along with a curated set of tools that dramatically improve the command-line experience.

*   **`zsh-syntax-highlighting`**: Provides real-time highlighting for commands you type.
*   **`fzf`**: A lightning-fast fuzzy finder for files and command history.
*   **`starship`**: A minimal, fast, and infinitely customizable prompt for any shell.

Install them all with a single `pacman` command:

```bash
sudo pacman -S --needed zsh zsh-syntax-highlighting fzf starship
```

---

## Step 2: Set Zsh as Your Default Shell

To make Zsh your login shell, use the `chsh` (change shell) command.

```bash
chsh -s $(which zsh)
```

> [!IMPORTANT]
> For the change to take full effect, you must **log out and log back in**. Simply opening a new terminal window is not enough.

After logging back in, you can verify that your shell has been changed:

```bash
echo $SHELL
```

The output should be `/bin/zsh` or `/usr/bin/zsh`.

---

## Step 3: Configure Zsh (`~/.zshrc`)

When Zsh starts for the first time, it may ask you to create a configuration file. You can choose to create a basic one or start from scratch. We will create our own to enable the plugins we installed.

Your Zsh configuration lives in the `~/.zshrc` file. Create it if it doesn't exist, and add the following lines to enable the plugins and Starship prompt.

```bash
# ~/.zshrc

# Enable syntax highlighting
# Note: This path is for the Arch Linux package.
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh


# Initialize Starship prompt
eval "$(starship init zsh)"

# (Optional) Add other aliases and functions below
# alias ls='eza --icons'
# alias cat='bat'
```

> [!TIP] Applying Changes
> After saving your `~/.zshrc` file, you can apply the changes immediately by either restarting your terminal or running:
> ```bash
> source ~/.zshrc
> ```

---

## Step 4: (Optional) Configure the Starship Prompt

[[Starship]]
---

## Step 5: Exploring Zsh Options Interactively

Zsh has a vast number of internal options that control its behavior. You can explore these directly from your terminal, which is excellent for learning and troubleshooting.

| Command | Description |
| :--- | :--- |
| `set -o` | Lists all Zsh options that are currently **enabled**. |
| `setopt` + `Tab` | Pressing Tab after `setopt` will show a list of all available options you can **turn on**. |
| `unsetopt` + `Tab` | Pressing Tab after `unsetopt` will show a list of all available options you can **turn off**. |

> [!NOTE]
> `unsetopt` is the standard command for disabling an option. The `nosetopt` command mentioned in the original note is less common.

