
# 🎨 General Theming on Arch Linux

This guide provides a comprehensive overview of theming various components of your Arch Linux desktop, including the Kitty terminal, GTK applications, and integrating them with `pywal` for a cohesive, dynamic look.

---

## 🖌️ Dynamic Theming with `pywal`

`pywal` is a powerful tool that generates a color palette from an image. These instructions detail how to integrate it with your wallpaper manager and terminal.

### Syncing `pywal` with Your `swww` Wallpaper

To ensure your system's theme always matches your current wallpaper, you can create a script or alias that tells `pywal` to generate colors from the image currently set by `swww`.

Run the following command to generate and apply a new color scheme without changing the wallpaper itself:

```bash
wal -n -i "$(swww query | grep -oP 'image: \K.*' | head -n 1)"
```

> [!NOTE] Command Breakdown
> *   `wal -n -i ...`: Runs `pywal` with the `-n` (skip setting wallpaper) and `-i` (input image) flags.
> *   `swww query`: Asks the `swww` daemon for the path to the current wallpaper.
> *   `grep -oP 'image: \K.*'`: Filters the output to extract only the image path.
> *   `head -n 1`: Ensures only the first wallpaper path is used (in case of multiple monitors).

### Applying `pywal` Themes to Kitty

After `pywal` runs, it generates configuration files for various applications, including Kitty. To make Kitty automatically use the generated theme, you need to edit its configuration file.

1.  Open your Kitty configuration file, located at `~/.config/kitty/kitty.conf`.
2.  Find the line that includes the theme file.
3.  Change it to point directly to the `pywal` cache file.

**Change this:**
```conf
# Old configuration
include current-theme.conf
```

**To this:**
```conf
# New configuration pointing to pywal's output
include ~/.cache/wal/colors-kitty.conf
```

> [!TIP]
> With this change, Kitty's colors will automatically update every time you run `wal` to generate a new theme. Simply restart Kitty (or reload its config with `Ctrl+Shift+F5`) to see the changes.

---

## 🖼️ GTK Theming

GTK themes control the appearance of most graphical applications on your desktop.

### Installing GTK Themes

There are two primary methods for installing GTK themes:

#### Method 1: Manual Installation (from GNOME-Look, GitHub, etc.)

This method is for themes you download directly from the web.

1.  **Download** the theme, which is typically a `.zip` or `.tar.gz` archive.
2.  **Extract** the archive. You will have a new folder containing the theme files.
3.  **Move** the theme folder into one of the following directories:

| Directory | Scope | Description |
| :--- | :--- | :--- |
| `~/.themes/` | **User-Specific** | The theme will only be available for your user account. This is the recommended location. |
| `~/.local/share/themes/` | **User-Specific** | An alternative user-specific directory. |
| `/usr/share/themes/` | **System-Wide** | The theme will be available to all users on the system. Requires `sudo` permissions. |

> [!SUCCESS] Example: Installing the "decay-green" theme
> After downloading and extracting the `decay-green` theme, copy its directory to your local themes folder with this command:
> ```bash
> # Assuming the extracted folder is named 'decay-green'
> cp -r /path/to/downloaded/decay-green ~/.local/share/themes/
> ```

```bash
cp -r /mnt/media/Documents/do_not_delete_linux/themes/Decay-Green ~/.local/share/themes/
```

### Applying GTK Themes

Once a theme is installed, you need a tool to set it as the active theme. `nwg-look` is an excellent graphical tool for this.

1.  Install `nwg-look` if you haven't already.
2.  Launch it by typing `nwg-look` in your terminal.
3.  In the **GTK Themes** tab, select your newly installed theme from the list.
4.  Click **Apply** to see the changes immediately.
