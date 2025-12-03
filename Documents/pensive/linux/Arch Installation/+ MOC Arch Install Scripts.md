### 1. *WiFi Connection*
```bash
iwctl
```

```bash
device list
```

- *Replace wlan0 with your device name from above eg: wlan1* or what ever your deivce is called

```bash
station wlan0 scan
```

```bash
station wlan0 get-networks
```

```bash
station wlan0 connect "Near"
```

```bash
exit
```

```bash
ping -c 2 x.com
```

- [ ] Status

```bash
pacman -Sy git
```

```bash
git clone --depth 1 https://github.com/dusklinux/.git_dotfiles_dir.git dusk
```

dont forget the period at the end '.' after a space.  
```bash
cp dusk/user_scripts/arch_iso_scripts/001_pre_chroot/* .
```

then only run the 001, and 002 scripts 

then 
```bash
arch-chroot /mnt
```

then these commands again 

```bash
git clone --depth 1 https://github.com/dusklinux/.git_dotfiles_dir.git dusk
```

dont forget the period at the end '.' after a space.  

```bash
cp dusk/user_scripts/arch_iso_scripts/001_post_chroot/* .
```

and the just run the 002_ORCHESTRA.sh script and nothing else. this script will automatically run all the other scripts. if a script fails for some reason, you could run that particualr script manually. 