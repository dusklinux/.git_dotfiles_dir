# Running DaVinci Resolve on Wayland

> [!info] The Problem
> DaVinci Resolve is an Xorg application. When a global environment variable like `QT_QPA_PLATFORM="wayland:xcb"` is set for Wayland compatibility, it can prevent Resolve from launching correctly.

> [!tip] The Solution
> The solution is to temporarily *unset* this specific environment variable just for the DaVinci Resolve application, allowing it to fall back to XWayland without affecting your other Wayland-native apps.

---

## One-Time Launch Command

You can launch the application from your terminal with the correct environment by running:

```bash
env -u QT_QPA_PLATFORM /opt/resolve/bin/resolve
```
This command uses `env -u` to unset the `QT_QPA_PLATFORM` variable before executing the Resolve binary.

---

## Permanent Fix: Modify the .desktop File

To avoid typing the command every time, you can create a local copy of the application's desktop entry and modify its launch command.

### Step 1: Copy the Desktop File

First, find the original `.desktop` file and copy it to your local applications directory. This prevents your changes from being overwritten by system updates.

> [!warning] Always copy, don't edit the original!
> Editing the system-wide file in `/usr/share/applications/` is not recommended. Your changes will be lost during the next update. Copying it to `~/.local/share/applications/` ensures your custom version takes precedence and is preserved.

```bash
cp /usr/share/applications/DaVinciResolve.desktop ~/.local/share/applications/
```

### Step 2: Edit the Copied File

Now, open your new local `.desktop` file with a text editor.

```bash
nvim ~/.local/share/applications/DaVinciResolve.desktop
```

### Step 3: Modify the `Exec` Line

Inside the file, find the line that starts with `Exec=`.

> [!note]- It will look something like this:
> ```ini
> Exec=/opt/resolve/bin/resolve %u
> ```

Modify this line to include the `env -u QT_QPA_PLATFORM` command at the beginning.

> [!success]- Change it to this:
> ```ini
> Exec=env -u QT_QPA_PLATFORM /opt/resolve/bin/resolve %u
> ```

### Step 4: Save and Launch

Save the file and exit the editor. Now, when you launch DaVinci Resolve from your application launcher (like Rofi or Wofi), it will automatically use the modified command and start correctly.

---

### Summary of Recommendations

> [!summary] Key Principles for Compatibility
> - **Do not change `export QT_QPA_PLATFORM="wayland:xcb"`:** This global setting is correct and beneficial for your other Wayland-native applications.
> - **Do not add anything specific for Resolve:** The problem is an *existing* variable that Resolve can't handle. The solution is to *remove* it for that specific application, not add a new one.
> - **Focus on overriding the launch command:** The correct, targeted solution is to modify how a single problematic application is executed, leaving the rest of your system configuration intact.
