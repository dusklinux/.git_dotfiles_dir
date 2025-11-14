open the file 
```bash
nvim ~/.config/matugen/config.toml
```

```toml
[templates.gtk3]
input_path = '~/.config/matugen/templates/gtk-colors.css'
output_path = '~/.config/matugen/generated/gtk-3.css'

[templates.gtk4]
input_path = '~/.config/matugen/templates/gtk-colors.css'
output_path = '~/.config/matugen/generated/gtk-4.css'
post_hook = 'ln -nfs $HOME/.config/matugen/generated/gtk-3.css $HOME/.config/gtk-3.0/gtk.css; ln -nfs $HOME/.config/matugen/generated/gtk-4.css $HOME/.config/gtk-4.0/gtk.css; gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3"'
```

After the color pallette is generated at the path ~/.config/matugen/generated. create a symbolic link to the requisite gtk directories for each version
gtk3/gtk4

```bash
ln -nfs $HOME/.config/matugen/generated/gtk-3.css $HOME/.config/gtk-3.0/gtk.css && ln -nfs $HOME/.config/matugen/generated/gtk-4.css $HOME/.config/gtk-4.0/gtk.css
```

then run  these commands
 (for light mode)
```bash
gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3"; gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-{{mode}}
```

or

(for dark mode)
```bash
gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark"; gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-{{mode}}
```

---
## Unrelated but incredibly important!! 

this command actully works for changing the color scheme for gtk apps. 
all other commands fail but this works. 

light
```bash
gsettings set org.gnome.desktop.interface color-scheme prefer-light
```
dark
```bash
gsettings set org.gnome.desktop.interface color-scheme prefer-dark
```


found the above command from an online form 


Is it a pure-gtk4 application, or a libadwaita one?

For pure-gtk4, try to run gtk4-query-settings and check for the gtk-application-prefer-dark-theme key.

    If it’s FALSE, then the setting could not be set from xsettings, so try to enforce it in the settings.ini:

 ~/.config/gtk-4.0/settings.ini

[Settings]
gtk-application-prefer-dark-theme = true

    if it’s TRUE, then probably the application itself overwrites the setting (also the case when using libadwaita, see below)

Now, for libadwaita apps, the setting is by default read through xdg-portals, so you may need to install a portal interface like xdg-desktop-portal-gnome.
If you, like me, don’t use portals at all (I’m on Cinnamon), then you can set the environment variable ADW_DISABLE_PORTAL=1, in which case the dark theme setting will be read from gsettings, configure it as follow:

gsettings set org.gnome.desktop.interface color-scheme prefer-dark


