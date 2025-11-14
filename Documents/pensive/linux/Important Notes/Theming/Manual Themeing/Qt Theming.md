# Setting Up Qt Theming on Arch Linux with Hyprland using Kvantum

1. **Install necessary packages.** Make sure **`qt5ct`**, **`qt6ct`**, and **`kvantum`** (plus `kvantum-qt5` for Qt5) are installed, along with any icon/theme packs you like (e.g. `breeze-icons`). These tools let you configure Qt5/Qt6 styles and colors outside a full desktop environment. (For example, on Arch use: `sudo pacman -S qt5ct qt6ct kvantum kvantum-qt5 breeze-icons`
    
2. **Set Hyprland environment variables.** In your Hyprland config (`~/.config/hypr/hyprland.conf`), add a line to tell Qt apps to use `qt5ct` (which will auto-handle Qt6 via `qt6ct`):

```ini
export QT_QPA_PLATFORMTHEME=qt6ct
```
# or

- **Choose Kvantum in Qt Settings.** Launch the **Qt6 Configuration** tool (`qt6ct`) (or `qt5ct` similarly) and under **Appearance/Style**, select **“kvantum”** as the widget style. (If “kvantum” is not listed, ensure `kvantum-qt5` is installed and restart `qt6ct`.) This tells Qt to use Kvantum as its theme engine. After selecting Kvantum, you can also choose a color scheme or leave the default. Alternatively, setting the environment variable has the same effect. Kvantum will then read its theme from `~/.config/Kvantum/kvantum.kvconfig.

>[!important]+ This causes problems with hyprpolkitagent (not recommanded)

```ini
export QT_STYLE_OVERRIDE=kvantum 
```

---

3. **Create custom Kvantum theme folders.** Each Kvantum theme is kept in `~/.config/Kvantum/THEME_NAME/` and contains a `.kvconfig` file plus SVG images. To make a new theme: pick a base (or downloaded) Kvantum theme, copy its folder, and give it a new name in `~/.config/Kvantum/`. For example, download or locate a theme folder (with files like `MyTheme.kvconfig` and `MyTheme.svg`), then copy that entire folder into `~/.config/Kvantum/.
- You can also use Kvantum Manager (GUI) to “Install theme” from a folder. Once copied, open the theme’s `.kvconfig` file with a text editor. Inside, find the `[Colors: ...]` sections (e.g. **BackgroundNormal**, **ButtonNormal**, **Highlight**, etc.) and replace the hex codes (e.g. `#RRGGBB`) with your desired colors. Each hex code corresponds to a UI color (background, text, highlight, etc.) for that widget state. Save the file when done. (You may also need to edit the SVG assets if the theme has custom graphics, but many themes use simple solid-color SVGs.)

- **Activate and switch themes.** To use a theme, either open Kvantum Manager and select your new theme, or manually set it in `~/.config/Kvantum/kvantum.kvconfig`. In that file, change the line to `theme=YourThemeName For example:
```ini
[General]
theme=KvGnomeDark
```    

Save and close. When a Qt app starts, Kvantum will apply the colors from `MyTheme`. You can repeat this process for each theme folder you create. Later, a script can automate swapping by editing `kvantum.kvconfig` or calling Kvantum Manager. (If you also want a CSS-based approach, the Oomox/Themix tool can export a Qt style: use Themix-GUI → _Export → Base16 Plugin → qt-oomox-styleplugin_ and set `QT_STYLE_OVERRIDE=oomox` or run apps with `-style oomox` But manual Kvantum themes give precise hex control.)


4. **Test your themes.** Launch a Qt application (e.g. **Dolphin**, **Konsole**, or a Qt-based app like VLC) to see the new colors. If it looks wrong, check that `QT_QPA_PLATFORMTHEME` is set (via `env` or in a terminal run `echo $QT_QPA_PLATFORMTHEME`) and that the Qtconfig tool still shows Kvantum. You might need to close and reopen apps after changing the theme. Each Qt5/Qt6 app should now use the colors from your chosen Kvantum theme. Once verified, you can script theme switching by toggling the `theme=` line in `~/.config/Kvantum/kvantum.kvconfig` (and reloading or restarting apps), and similarly use your GTK-switch script to handle non-Qt apps.


if you want to change the file picker for qt apps. like when you need to pick a file and you hit brouse it opens the window for file manager, you can change that for qt in qt6ct under 

```ini
Appearance> Standard Dialogs:> Default/ GTK3/XDG Desktop Portal
```



## Turn off transparency

to turn off translucency aka transparency aka opacity for kvantum theme just switch the values for these to false. this is the theme_name.kvconfig file obviously. 
```ini
translucent_windows=false
blurring=true
popup_blurring=true
```

and also the following to 0

```ini
reduce_window_opacity=0
reduce_menu_opacity=0
```


also search for `transparent` , `translucent` and `blur` and change their values as well. (there are options/variables for these under the 'Hacks' section in the same file)

## Change color
just search for `color` in the theme_name.kvconfig file and change the values. 