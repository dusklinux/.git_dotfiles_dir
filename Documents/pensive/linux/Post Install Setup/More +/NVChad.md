# NVChad Installation Guide for Arch Linux

This guide provides a clear, step-by-step process for installing NVChad, a beautiful and feature-rich Neovim configuration, on an Arch Linux system.

---

### **Step 1: Fulfill Prerequisites**

Before installing NVChad, you must have a few essential components installed and configured.

#### **1.1. Install Git and Neovim**
NVChad is managed through Git and runs on Neovim. If you followed the base Arch installation guide and included the `base-devel` group, `git` should already be installed. Neovim is also a required package.

You can ensure they are installed with the following command:

```bash
sudo pacman -S --needed git neovim
```

#### **1.2. Install a Nerd Font**
NVChad's user interface relies heavily on icons for a clean and modern look. These icons are provided by Nerd Fonts. The **JetBrains Mono Nerd Font** is an excellent choice for its clarity and comprehensive icon set.

Install it using `pacman`:

```bash
sudo pacman -S --needed ttf-jetbrains-mono-nerd
```

> [!TIP] What are Nerd Fonts?
> Nerd Fonts are popular programming fonts that have been patched to include a large number of extra glyphs (icons). These are used by terminal applications and UI elements like those in NVChad to display status symbols, file type icons, and more.

---

### **Step 2: Configure Your Terminal**

Your terminal emulator must be configured to *use* the Nerd Font you just installed. The instructions below are for the **Kitty** terminal, a popular choice.

1.  Run Kitty's built-in font selection utility:
    ```bash
    kitten choose-font
    ```
2.  In the interactive menu, use the arrow keys to find and select `JetBrainsMono Nerd Font`.
3.  Press `Enter` to apply it.
4.  The utility will ask if you want to save this to your `kitty.conf`. Confirm this action.

> [!NOTE] Using a Different Terminal?
> If you are not using Kitty, you will need to consult the documentation for your specific terminal (e.g., Alacritty, WezTerm, GNOME Terminal) to learn how to change the font. The key is to set `JetBrainsMono Nerd Font` as your default monospace font.

---

### **Step 3: Install NVChad**

With the prerequisites in place, you can now install NVChad. This is done by cloning the official starter repository into your Neovim configuration directory.

> [!IMPORTANT] Backup Existing Configuration
> If you have an existing Neovim configuration at `~/.config/nvim`, the following command will overwrite it. Be sure to back it up first if you wish to keep it.
> ```bash
> # Optional: Backup your old config
> mv ~/.config/nvim ~/.config/nvim.bak
> ```

Now, run the installation command:

```bash
git clone https://github.com/NvChad/starter ~/.config/nvim && nvim
```

**Command Breakdown:**
*   `git clone ...`: This downloads the NVChad starter configuration from GitHub.
*   `~/.config/nvim`: This is the destination directory where Neovim looks for its configuration files.
*   `&& nvim`: After the `git clone` command succeeds, this part immediately launches Neovim.

---

### **Step 4: First Launch and Initialization**

When you launch `nvim` for the first time after cloning, NVChad will automatically begin its setup process.

1.  **Lazy.nvim:** You will see the `lazy.nvim` plugin manager interface appear. It will start downloading and installing all the plugins defined in the NVChad configuration.
2.  **Wait for Completion:** Allow this process to complete. It may take a few minutes, depending on your internet connection.
3.  **Restart Neovim:** Once all plugins are installed, close Neovim (`:q`) and restart it (`nvim`) to ensure everything is loaded correctly.

Your NVChad installation is now complete! You can begin exploring its features or proceed to customize it further.
