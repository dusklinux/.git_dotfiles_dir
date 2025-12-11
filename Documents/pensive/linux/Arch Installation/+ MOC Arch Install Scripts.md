> [!NOTE]- wifi connect , Skip if youre connected via lan/usb teathering
> ### 1. *WiFi Connection*
> ```bash
> iwctl
> ```
> 
> ```bash
> device list
> ```
> 
> - *Replace wlan0 with your device name from above eg: wlan1* or what ever your deivce is called
> 
> ```bash
> station wlan0 scan
> ```
> 
> ```bash
> station wlan0 get-networks
> ```
> 
> ```bash
> station wlan0 connect "Near"
> ```
> 
> ```bash
> exit
> ```
> 
> ```bash
> ping -c 2 x.com
> ```
> 
> - [ ] Status

```bash
pacman -Sy git
```

```bash
git clone --depth 1 https://github.com/dusklinux/dusky.git dusk
```

dont forget the period at the end '.' after a space.  
```bash
cp dusk/user_scripts/arch_iso_scripts/000_pre_chroot/* .
```

you only need to run the 000_ISO_ORCHESTRA.SH script. dont run anything else, this script auto runs eveyrthing. 

```bash
./000_ISO_ORCHESTRA.sh
```


after you've run all the scripts 
```bash
arch-chroot /mnt
```

and the just run the 001_CHROOT_ORCHESTRA.sh script and nothing else. this script will automatically run all the other scripts. if a script fails for some reason, you could run that particular script manually.

```bash
./001_CHROOT_ORCHESTRA.sh
```

after the scrpts finish . 

boot into the os . login> and run 
```bash
./deploy_dotfiles.sh
```

then run , and follow the on screen instructions. it's just yes or no questions. 
```bash
./user_scripts/arch_setup_scripts/ORCHESTRA.sh
```

