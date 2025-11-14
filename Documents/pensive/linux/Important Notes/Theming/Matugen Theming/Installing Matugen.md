first install matugen, (multiple ways of doing so, all same result)
recommanded is the cargo version 
```bash
cargo install matugen
```

or from the aur
```bash
paru --needed -Syyu matugen-bin
```

or from the extra repo arch
```bash
sudo pacman --needed -Syyu matugen
```

first install this template for gtk 

```bash
sudo pacman --needed -Syu adw-gtk-theme
```


create the folders 
```bash
mkdir -p ~/.config/matugen/{generated,templates}
```

create the toml config file

```bash
touch ~/.config/matugen/config.toml
```

go to the place where you'll temerarly download the templates from github

```bash
cd /mnt/zram1/
```

then download the github
```bash
https://github.com/InioX/matugen-themes
```

unzip it with the uzip command
```bash
unzip file.zip
```

and copy the templates directory's contents into the previously created templates directory

