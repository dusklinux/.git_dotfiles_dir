
After your system automatically logs into TTY1, your default shell (e.g., Zsh) will start. We need to add a command to its startup file (`~/.zshrc`) to launch the Hyprland session.

> [!TIP] Using a Different Shell?
> If you use Bash, add the script to `~/.bash_profile`. This file is specifically sourced for login shells, which is what a TTY session is.

### Recommended Method (Robust and Specific)

This script is the recommended approach because it includes checks to ensure it only runs when you are on TTY1 and a graphical session (`$DISPLAY`) is not already active. This prevents it from running in unintended situations, like when you open a new terminal inside Hyprland.

Add the following snippet to the end of your `~/.zshrc` file:

```sh
# Automatically start Hyprland on TTY1
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
  if uwsm check may-start; then
    exec uwsm start hyprland.desktop
  fi
fi
```

#### Script Breakdown
- **`if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]`**: This condition checks two things:
    1. Is the `$DISPLAY` environment variable empty? (Confirms no X11/Wayland session is running).
    2. Is the current terminal `/dev/tty1`?
- **`if uwsm check may-start`**: This uses the **Universal Wayland Session Manager** (`uwsm`) to verify that it's safe to start a new session.
- **`exec uwsm start hyprland.desktop`**: The `exec` command replaces the current shell process with the `uwsm` command, which then starts Hyprland. This is a clean way to hand over control to the graphical session.

### Optional Method (Simpler)

This version is less specific and will attempt to start Hyprland whenever the shell starts and `uwsm` allows it. It's simpler but less robust than the recommended method.

```sh
# Simpler auto-start for Hyprland
if uwsm check may-start; then
    exec uwsm start hyprland.desktop
fi
```

After saving the changes to your `.zshrc` or `.bash_profile`, the setup is complete. The next time you reboot your system, it should automatically log you in and launch your Hyprland desktop.

