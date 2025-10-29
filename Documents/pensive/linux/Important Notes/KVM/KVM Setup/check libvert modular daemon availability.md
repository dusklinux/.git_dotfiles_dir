

To find which package owns a file, you can use the -F flag with pacman. It's recommended to first synchronize/refresh the package file database:

```bash
sudo pacman -Fy
```

This command will output the package that provides the virtqemud.service file.

```bash
pacman -F virtqemud.service
```

