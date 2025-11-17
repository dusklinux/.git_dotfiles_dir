

### It shoudl already have the requisite permission, but if not, run:
since this is a root dir/ it needs root executable permissions. 

```bash
sudo chmod 755 ~/user_scripts/external/usb_sound.sh
```

### symlink the existing script to the usr/local/bin directory. 

```bash
sudo ln -nfs ~/user_scripts/external/usb_sound.sh /usr/local/bin/
```




### the udev rule to be added in

```bash
sudo nvim /etc/udev/rules.d/90-usb-sound.rules
```

### copy paste this into the file. 
This rule points to a standard, system-wide location. This is the correct and portable way to handle a system-level event. 

```ini
ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", RUN+="/usr/local/bin/usb_sound.sh connect"
ACTION=="remove", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", RUN+="/usr/local/bin/usb_sound.sh disconnect"
```


and then run this 

```bash
sudo udevadm control --reload-rules
```

--- 

this is not usually needed **(Dont run)**

```bash
sudo udevadm trigger --action=add
```