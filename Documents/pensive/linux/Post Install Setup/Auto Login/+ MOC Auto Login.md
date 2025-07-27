
> [!abstract] Overview
> This guide outlines the process for configuring your Arch Linux system to bypass the login prompt and automatically launch a Hyprland session upon boot. This is particularly useful for single-user machines where you want to get to your desktop environment as quickly as possible.

---

## The Process at a Glance

The setup involves three main stages that must be completed chronologically. Each step is detailed in its own note.

1.  **[[Disable SDDM]]** (if installed)
    First, you must disable any existing display manager (like SDDM or GDM) to prevent it from conflicting with the new TTY auto-login method.

2.  **[[Configure TTY1 for Automatic Login]]**
    Next, you will configure `systemd` to automatically log your user into the TTY1 virtual console, bypassing the need to enter a username or password.

3.  **[[Automatically Launch Hyprland from Zsh]]**
    Finally, you will add a script to your shell's configuration file (e.g., `~/.zshrc`) that automatically starts the Hyprland session as soon as the TTY login is complete.

Follow the guides linked above in sequence to ensure a smooth setup.
