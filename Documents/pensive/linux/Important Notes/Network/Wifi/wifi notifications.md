have this installed 

```bash
sudo pacman -S --needed network-manager-applet
```

you'll automaticlay get notified, when connected/disconnected when it's running with 
```bash
nm-applet
```

if you turned off notificaitons by clicking the dont get notifications again, 
you can turn them back on with this command 
```bash
gsettings set org.gnome.nm-applet disable-connected-notifications false
gsettings set org.gnome.nm-applet disable-disconnected-notifications false
```