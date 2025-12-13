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

this often fails on the first try for some reason, run it as many times as it takes to have it install sucessfully, if running it multiple times with failur results it with askign you to delte pacman keys, pick yes for deleting, it'll repopulate the keys. 
```bash
pacman -Sy git
```

```bash
git clone --depth 1 https://github.com/dusklinux/dusky.git
```

dont forget the period at the end '.' after a space.  
```bash
cp dusky/user_scripts/arch_iso_scripts/000_pre_chroot/* .
```

You only need to run the 000_ISO_ORCHESTRA.SH script. dont run anything else, this script auto runs eveyrthing. 

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

after booting. 
put in your password and user name
and then. 
```bash
./wifi_connect.sh
```

then. deploy git repo, open the terminal with super Q
```bash
./deploy_dotfiles.sh
```

then run the setup orchestra script
```bash
./user_scripts/arch_setup_scripts/ORCHESTRA.sh
```