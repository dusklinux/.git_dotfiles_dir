### Installation on host os
```bash
sudo pacman -Syyu --needed gnome-boxes virt-manager spice spice-gtk spice-protocol gvfs-dnssd wl-clipboard xclip
```

to configure gnome-boxes's config on host. using virt-manager, this opens the user session rather than the defualt root session which doesnt include gnome boxes. click the lightbulb/ "i" in a circle right next to the monitor icon on the top left   
```bash
virt-manager --connect qemu:///session
```

on gues os for clipboard sharing
```bash
sudo pacman -S --needed  spice-vdagent wl-clipboard xclip
```
on guest start spice-vdagent
```bash
spice-vdagent
```
or to make it perminitnet, add to hyprland config on guest. 
```ini
# Start the SPICE user agent
exec-once = spice-vdagent

# (Optional) Force bridge if the above isn't enough
exec-once = wl-paste -t text --watch xclip -selection clipboard
```

if it doesn't work ont guest run it all on guest. not on host .
```bash
# 1. Ensure the driver is loaded (Just in case)
sudo modprobe virtio_console

# 2. Kill any stuck processes
killall spice-vdagent wl-paste 2>/dev/null

# 3. Start the User Agent (Talks to the Host)
spice-vdagent

# 4. Start the Bridge (Talks to Hyprland)
# This is the piece you were missing in the last screenshot!
wl-paste --type text --watch xclip -selection clipboard & disown
```

this one sends the clipboard content only once to the guest. (run on host) 
```bash
wl-paste | xclip -selection clipboard
```
or this for persistence until the terminal is closed (run on host)

```bash
wl-paste -t text --watch xclip -selection clipboard
```

open gnome-boxes once. but dont' install anything yet.

change the temp directory for os installation to zram

```bash
mkdir -p /mnt/zram1/boxes_vm/ && rm -rf ~/.local/share/gnome-boxes/images && ln -nfs /mnt/zram1/boxes_vm $HOME/.local/share/gnome-boxes/images
```

```bash
sudo systemctl enable --now libvirtd.service
```

```bash
sudo usermod -a -G libvirt,kvm $USER
```

to check logs for it 
```bash
journalctl --user -b -g 'gnome.Boxes'
```