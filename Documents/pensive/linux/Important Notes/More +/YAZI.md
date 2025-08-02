# 🚀 A Guide to Yazi: The Blazing-Fast Terminal File Manager

Welcome to your new command-line companion. Yazi is a terminal file manager written in Rust, designed for exceptional speed, a modern user experience, and powerful features like multi-pane layouts, asynchronous operations, and Vim-like keybindings.

This guide will walk you through installing, configuring, and mastering Yazi on Arch Linux, transforming it from a simple tool into an integral part of your workflow.

---

## 1. Installation on Arch Linux

First, we need to install Yazi and its essential dependencies. While Yazi can function on its own, its true power is unlocked with tools like `fd` (for searching), `ripgrep` (for content searching), `fzf` (for fuzzy finding), and `zoxide` (for intelligent directory jumping).

> [!NOTE] Recommended Dependencies
> The following command installs Yazi along with its most powerful companions. These are highly recommended for accessing all the features listed in the keybindings section.

Execute the following command in your terminal to install everything you need:

```bash
sudo pacman -S --needed yazi fd ripgrep fzf zoxide
```

---

## 2. First Launch & Configuration

Once installed, you can launch Yazi by simply typing its name in the terminal:

```bash
yazi
```

### Configuration Files

Yazi is configured through three simple `.toml` files located in your user's config directory.

*   **Location:** `~/.config/yazi/`
*   **Files:**
    *   `yazi.toml`: General settings, UI layout, and behavior.
    *   `keymap.toml`: All keybindings.
    *   `theme.toml`: Colors, icons, and overall appearance.

> [!TIP] Customizing Yazi
> Yazi works perfectly out of the box with sensible defaults. To customize it, you can copy the default configuration files into your `~/.config/yazi/` directory and edit them. You can find the default files in the Yazi documentation or source repository.

---

## 3. The Yazi Interface: A Quick Tour

Yazi's interface is clean and intuitive, typically divided into three vertical panes:

| Pane | Description |
|:---|:---|
| **Parent Directory** | (Left) Shows the contents of the directory containing your current one. |
| **Current Directory**| (Middle) The main pane, showing files and folders in your active location. |
| **Preview** | (Right) Displays a preview of the hovered file (text, images, archives, etc.). |

---

## 4. Keybindings Reference

Yazi uses Vim-like keybindings for fast, keyboard-driven navigation and file management.

### Essential Navigation

These are the fundamental keys for moving around.

| Key(s) | Action |
|:---|:---|
| `k` or `Up` | Move the cursor up |
| `j` or `Down` | Move the cursor down |
| `h` or `Left` | Go to the parent directory |
| `l` or `Right` | Enter the hovered directory |
| `gg` | Jump to the top of the file list |
| `G` | Jump to the bottom of the file list |
| `.` | Toggle the visibility of hidden files |

### Advanced Navigation & Jumping

Quickly jump across your filesystem using integrated tools.

| Key | Action |
|:---|:---|
| `z` | Jump to a directory using **zoxide** (intelligent `cd`) |
| `Z` | Jump to a directory or reveal a file using **fzf** (fuzzy finder) |

### File Operations

The core commands for managing your files.

> [!WARNING] Deletion Actions
> Be mindful of the difference between `d` and `D`.
> - `d`: Moves files to the system's trash, which is recoverable.
> - `D`: **Permanently deletes** files, bypassing the trash. This action cannot be undone.

| Key | Action |
|:---|:---|
| `Enter` or `o` | Open the selected file(s) with the default application |
| `O` | Open selected file(s) interactively (choose application) |
| `y` | **Y**ank (copy) selected files |
| `x` | Cut selected files |
| `p` | **P**aste yanked/cut files |
| `P` | Paste and overwrite if the destination file already exists |
| `d` | Move selected files to **Trash** |
| `D` | **Permanently Delete** selected files |
| `a` | Create a new file (add `/` at the end for a directory) |
| `r` | **R**ename the selected file(s) |

### Selection

Select one or more files to perform batch operations.

| Key | Action |
|:---|:---|
| `Space` | Toggle selection for the hovered file |
| `v` | Enter **V**isual mode to select multiple files with navigation keys |
| `V` | Enter **V**isual mode (unset mode) |
| `Ctrl` + `a` | Select **A**ll files in the current directory |
| `Ctrl` + `r` | Inve**r**se the current selection |
| `Esc` | Clear the current selection |

### Searching & Filtering

Find what you're looking for, from the current directory to your entire system.

| Key | Action |
|:---|:---|
| `f` | **F**ilter the files in the current view by name |
| `/` | **F**ind the next file matching a pattern (forwards) |
| `?` | **F**ind the previous file matching a pattern (backwards) |
| `n` | Go to the **n**ext match from a find |
| `N` | Go to the previous match from a find |
| `s` | **S**earch files by name using `fd` |
| `S` | **S**earch files by content using `ripgrep` |

### Sorting

Dynamically reorder the file list to suit your needs.

| Key | Sort By | Key | Sort By (Reverse) |
|:---|:---|:---|:---|
| `,m` | **M**odified time | `,M` | Modified time (reverse) |
| `,b` | **B**irth time | `,B` | Birth time (reverse) |
| `,e` | File **e**xtension | `,E` | File extension (reverse) |
| `,a` | **A**lphabetically | `,A` | Alphabetically (reverse) |
| `,n` | **N**aturally | `,N` | Naturally (reverse) |
| `,s` | **S**ize | `,S` | Size (reverse) |
| `,r` | **R**andomly | | |

### Tab Management

Use tabs to manage multiple directories at once.

| Key | Action |
|:---|:---|
| `t` | Create a new **t**ab |
| `[` | Switch to the previous tab |
| `]` | Switch to the next tab |
| `{` | Swap the current tab with the previous one |
| `}` | Swap the current tab with the next one |
| `Ctrl` + `c` | **C**lose the current tab |
| `1`-`9` | Switch to the N-th tab |

### Shell & System Interaction

Run commands and copy paths without leaving the file manager.

| Key | Action |
|:---|:---|
| `;` | Run a shell command (asynchronously) |
| `:` | Run a shell command and wait for it to finish |
| `cc` | **C**opy the full file **p**ath |
| `cd` | **C**opy the **d**irectory path |
| `cf` | **C**opy the **f**ilename only |
| `cn` | **C**opy the file**n**ame without its extension |

