# To change Gtk theme with a command 

```bash
gsettings set org.gnome.desktop.interface gtk-theme "YourThemeName"
```

---
# Customizing GTK4/Libadwaita Themes

GNOME has created a new library for GTK4 apps called libadwaita, keep in mind that libadwaita and GTK4 are separate entities with libadwaita depending on GTK4. They are not the same. This library has dropped the easy way to switch CSS stylesheet in favor of a more solid theming API foundation starting with recoloring.

This is a note about libadwaita AMONG OTHER RELATED THINGS, also GTK-non-libadwaita GTK4 apps are unaffected by this.


This guide walks you through a method to apply custom stylesheets to Libadwaita applications, effectively theming them. It involves linking your preferred theme's GTK-4.0 assets to the user's configuration directory.

> [!WARNING] Important Disclaimers
> 
> - **This is an unsupported hack.** This method is not officially supported by the GNOME team.
>     
> - For any visual bugs or issues, please report them to your **theme's developer**, not to GNOME.
>     
> - This method will **not work** with themes that package their assets within a gtk.gresource file.
>     

---

## Recommended Method: Using Symbolic Links

This is the preferred method because any updates to your theme will be automatically reflected without needing to copy the files again.

### Step 1: Locate Your Theme's gtk-4.0 Folder

First, navigate to the directory where your installed themes are located, which is typically  or . Find the specific theme you want to use and enter its gtk-4.0 subdirectory.

`user directory (Recommanded)

```bash
cd ~/.local/share/themes/
```
### or 

`Root directory`

```bash
cd /usr/share/themes
```
  

### Step 2: Prepare the Destination Folder

You need to place the theme files in your user's local configuration directory. Navigate to ~/.config/. If a folder named gtk-4.0 does not exist here, create it.

```bash
mkdir -p ~/.config/gtk-4.0 && cd ~/.config/gtk-4.0
```

### Step 3: Symbolically Link the Theme Files

Now, create symbolic links from the theme's files (from Step 1) into the ~/.config/gtk-4.0 directory (from Step 2).

> [!TIP] How to Create Symbolic Links  
 > 1. **Terminal (Recommended):** Use the ln -nfs command for each file. The * wildcard makes this easy.


Here is the recommended terminal command to link all the files at once. 

`(Replace YourThemeName with the actual name of your theme's folder)`
the -f flag is to remove existing destination files

```bash
ln -nfs $HOME/.local/share/themes/YourThemeName/gtk-4.0/* $HOME/.config/gtk-4.0/
```  

After linking, the contents of your ~/.config/gtk-4.0 folder should show links to the original gtk 4 theme files.

### Step 4: Enjoy Your Themed Apps!

Your Libadwaita applications should now reflect the custom theme.

---

## Alternative Method: Copying Files

If you prefer not to use symbolic links, you can simply copy the files. The main drawback is that you will need to manually re-copy the files every time your theme receives an update.

>[!tip] Replace `YourThemeName` with actual Theme name

1. **Navigate** to your theme's gtk-4.0 folder 
```bash
cd $HOME/.local/share/themes/YourThemeName/gtk-4.0/
```
 
3. **Copy** ALL the contents of this folder (assets, gtk.css, etc.).

```bash
mkdir -p ~/.config/gtk-4.0
cp -r $HOME/.local/share/themes/YourThemeName/gtk-4.0/* $HOME/.config/gtk-4.0/
cd ~/.config/gtk-4.0
```

That's it. 

---

## Applying Themes to Flatpak Apps

> [!INFO] System-Wide Flatpak Override  
> To make your custom theme visible to Flatpak applications, you need to grant them permission to access the theme and configuration directories. You can do this by running the following commands in your terminal.

```bash
flatpak --user override --filesystem=~/.local/share/themes/YourThemeName
flatpak --user override --filesystem=~/.config/gtk-4.0`
```  

## Bonus: Customizing Theme Colors

If you want to go a step further and change the colors of a theme to your own custom palette, you can do so by editing the theme's CSS files directly.

1. Navigate into your theme's folder (e.g., ~/.themes/YourTheme/).
  
2. Look for the gtk-3.0 and gtk-4.0 directories. The color definitions are usually within gtk.css or other imported CSS files inside these folders.
  
3. Open the gtk.css file and search for color definitions. A common variable name for the main background color is bg_color something something or fg_color something something.

4. To replace a color across the entire file, you can use a search-and-replace command. For example, in Neovim (or Vim), you can use the following command in normal mode to replace an old color hex code with a new one:

```ini
:%s/old_color_hex/new_color_hex/g
``` 

*Example: 

```ini
:%s/#363a45/#2E2E34/g
```