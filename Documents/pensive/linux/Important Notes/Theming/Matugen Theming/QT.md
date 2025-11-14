
open this file and paste this. 
```bash
nvim ~/.config/matugen/config.toml
```

qt5ct/qt6ct

```toml
[config]

[templates.qt5ct]
input_path = '~/.config/matugen/templates/qtct-colors.conf'
output_path = '~/.config/matugen/generated/qt5ct-colors.conf'

[templates.qt6ct]
input_path = '~/.config/matugen/templates/qtct-colors.conf'
output_path = '~/.config/matugen/generated/qt6ct-colors.conf'
```



for qt5ct
open this file 

```bash
nvim ~/.config/qt5ct/qt5ct.conf
```

replace these lines at the top of the file with this

```bash
[Appearance]
color_scheme_path=$HOME/.config/matugen/generated/qt5ct-colors.conf
custom_palette=true
style=Fusion
```

for qt6ct
open this file 

```bash
nvim ~/.config/qt6ct/qt6ct.conf
```

replace these lines at the top of the file with this

```bash
[Appearance]
color_scheme_path=$HOME/.config/matugen/generated/qt6ct-colors.conf
custom_palette=true
style=Fusion
```

that's it

---
---
### Qt-Method-2

Note: the output path needs to be `~/.local/share/color-schemes/` in order for qt*ct to be able to find the color sheme

```toml
[templates.color-scheme]
input_path = '~/.config/matugen/templates/Matugen.colors'
output_path = '~/.local/share/color-schemes/Matugen.colors'
```

Next, pick what style you would like to use `kde` or `Darkly` and ajust the code below.

Then, add these four lines to the top of `~/.config/qt5ct/qt5ct.conf` and do the same for qt6

```
color_scheme_path=~/.local/share/color-schemes/Matugen.colors
custom_palette=true
icon_theme=breeze
style=<Breeze or Darkly>
```

Finally, make sure you have this environment variable `QT_QPA_PLATFORMTHEME` set to `qt6ct`.

Note

for the theme to work you need to install the following  
Arch Linux (AUR):

- `yay -S breeze-icons breeze-gtk qt6ct-kde qt5ct-kde`  
    

For a kde style look download the following packages:

```
pacman -S --needed breeze breeze5
```

For a cleaner style download the following packages:

```
yay -S darkly-qt5-git darkly-qt6-git
```