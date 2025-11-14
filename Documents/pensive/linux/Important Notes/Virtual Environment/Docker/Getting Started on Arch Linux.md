Getting Started on Arch Linux

### 1. Installation

```bash
# Install the docker package from the official repositories
sudo pacman -S --needed docker
```

### 2. Service Management

```bash
# Start the Docker background service (daemon)
sudo systemctl start docker.service

# Enable the service to start automatically on boot
sudo systemctl enable docker.service
```

### 3. Post-Installation (Crucial Step)

To run `docker` commands without `sudo` every time, add your user to the `docker` group.

```bash
# Add your current user to the 'docker' group
sudo usermod -aG docker $USER
```

> [!WARNING] Log Out and Log Back In!
> This group change will **not** take effect until you completely log out of your session and log back in, or reboot. This step is essential for a smooth experience. Granting access to the Docker socket is equivalent to giving passwordless root access, so be aware of the security implications on a multi-user system.

---
