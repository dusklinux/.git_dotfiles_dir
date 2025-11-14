
# 🎨 General Theming on Arch Linux

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
