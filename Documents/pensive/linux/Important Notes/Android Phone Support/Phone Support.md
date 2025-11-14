### Android phone files/ mtp/ phone support. 
```bash
sudo pacman -Syu --needed base-devel git libmtp gvfs gvfs-mtp mtpfs android-file-transfer android-udev android-tools gvfs-gphoto2 gvfs-afc kio-extras fuse2 usbutils --noconfirm
```

```bash
paru -S --needed jmtpfs simple-mtpfs go-mtpfs-git --noconfirm
```
### What this installs (short rationale)

- `libmtp` — core MTP library (device support & `mtp-detect`). [wiki.archlinux.org](https://wiki.archlinux.org/title/Media_Transfer_Protocol)
    
- `gvfs`, `gvfs-mtp` — GNOME-style file-manager integration; lets file managers (Nautilus, PCManFM, etc.) show MTP devices automatically and mount to `/run/user/$UID/gvfs/`. [wiki.archlinux.org](https://wiki.archlinux.org/title/Media_Transfer_Protocol)
    
- `mtpfs`, `jmtpfs`, `simple-mtpfs`, `go-mtpfs` — FUSE-based mount tools (different devices behave differently; try more than one if one fails). `mtpfs` is in official repos; `jmtpfs`/`simple-mtpfs`/`go-mtpfs` are AUR. [wiki.archlinux.org+2Arch Linux+2](https://wiki.archlinux.org/title/Media_Transfer_Protocol)
    
- `android-file-transfer` (`aft-mtp-*`) — another MTP client / FUSE wrapper (useful when other libs fail). [wiki.archlinux.org](https://wiki.archlinux.org/title/Media_Transfer_Protocol)
    
- `android-udev` — udev rules so hotplug detection / permissions work (very useful so non-root can access devices). [Arch Linux](https://archlinux.org/packages/extra/any/android-udev/?utm_source=chatgpt.com)
    
- `android-tools` — `adb`/`fastboot` (useful for debugging or if you want `adb pull`/`adb push`). [Arch Linux](https://archlinux.org/packages/extra/x86_64/android-tools/?utm_source=chatgpt.com)
    
- `gvfs-gphoto2` — PTP / camera access (photos) if your device chooses PTP instead of MTP. [wiki.archlinux.org](https://wiki.archlinux.org/title/Media_Transfer_Protocol)
    
- `kio-extras` — KIO MTP support for KDE/Dolphin (if you use Dolphin). [wiki.archlinux.org+1](https://wiki.archlinux.org/title/Media_Transfer_Protocol)
    
- `nautilus` / `dolphin` — examples of GUI file managers that integrate with gvfs / kio (optional; remove if you already have a file manager you prefer). [wiki.archlinux.org+1](https://wiki.archlinux.org/title/Media_Transfer_Protocol)
    
- `fuse2` / `base-devel` / `git` / `usbutils` — building & using FUSE mounts and useful tooling.
    

### Quick usage notes / gotchas

- After installing, reboot (recommended by ArchWiki) or at least re-login so udev rules and GVFS services start correctly. [wiki.archlinux.org](https://wiki.archlinux.org/title/Media_Transfer_Protocol)
    
- If you use a GUI file manager (Nautilus, Thunar with gvfs, Dolphin), the phone should appear automatically; GVFS mounts will live under `/run/user/$UID/gvfs/` (look for `mtp:host=...`). Use `gio mount -li` to list mounted gvfs volumes. [wiki.archlinux.org](https://wiki.archlinux.org/title/Media_Transfer_Protocol)
    
- If the phone is locked, FUSE mounts (e.g. `jmtpfs`) may fail — unlock the phone while mounting. (ArchWiki notes this common cause.) [wiki.archlinux.org](https://wiki.archlinux.org/title/Media_Transfer_Protocol)
    
- If one method fails (freezes on DCIM, input/output errors, unknown device), try a different client (e.g. if `gvfs-mtp`/`libmtp` misbehaves, try `jmtpfs` or `simple-mtpfs`). MTP is inconsistent across vendors; having multiple tools helps. [wiki.archlinux.org](https://wiki.archlinux.org/title/Media_Transfer_Protocol)
    
- If you want automatic mounting scripts, the wiki and community threads mention utilities / udev scripts — I can add a ready-to-use udev rule or `systemd` user service next if you want. [bbs.archlinux.org+1](https://bbs.archlinux.org/viewtopic.php?id=282764&utm_source=chatgpt.com)

```bash
mkdir -p ~/Phone
jmtpfs ~/Phone     # or: simple-mtpfs ~/Phone
fusermount -u ~/Phone   # to unmount
```

Reboot or re-login once so the udev rules take effect. After that, this setup is rock solid for Android <-> Arch file transfers — even in Hyprland / pure Wayland environments.
