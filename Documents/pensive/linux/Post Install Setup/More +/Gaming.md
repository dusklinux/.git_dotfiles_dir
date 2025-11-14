to download steam, you need to enable the multilib repo first in 

```bash
sudo nvim /etc/pacman.conf
```

towards the bottom of the file are two commented out lines that you need to uncomment 

```bash
[multilib]
Include = /etc/pacman.d/mirrorlist
```

then instlall steam 
```bash
sudo pacman --needed -Syu steam lutris wine gamemode mangohud gamescope
```

then install protontricks

```bash
paru --needed -Syu protontricks
```