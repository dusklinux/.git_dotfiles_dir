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
git clone --depth 1 https://github.com/dusklinux/.git_dotfiles_dir.git dusk
```

```bash

```