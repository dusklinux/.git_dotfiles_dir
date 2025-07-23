
After installing packages, the next crucial step is to enable the essential services that will run in the background. These services manage everything from power and networking to hardware and system maintenance.


This guide separates services into three categories:
1.  **System-Wide Services**: Run with root privileges for all users.
2.  **User-Specific Services**: Run for a specific user without root privileges.
3.  **Optional Services**: Enabled only if you installed the corresponding packages.

## System-Wide Services

These services are enabled system-wide and will start automatically at boot.

> [!TIP] Combine and Conquer
> You can enable multiple services at once by listing them in a single `systemctl enable` command.

Run the following command from your `chroot` environment to enable the core system services:

```bash
systemctl enable NetworkManager.service tlp.service udisks2.service thermald.service bluetooth.service firewalld.service fstrim.timer systemd-timesyncd.service acpid.service vsftpd.service
```

### Core System Services Overview

| Service | Description |
| :--- | :--- |
| `NetworkManager.service` | Manages network connections (Wi-Fi, Ethernet). |
| `tlp.service` | Optimizes battery life and power management. |
| `udisks2.service` | Manages storage devices and media (e.g., auto-mounting USB drives). |
| `thermald.service` | Prevents overheating by monitoring and controlling CPU temperature. |
| `bluetooth.service` | Manages Bluetooth devices. |
| `firewalld.service` | Provides a dynamic firewall for system security. |
| `fstrim.timer` | Periodically issues TRIM commands to SSDs to maintain performance. |
| `systemd-timesyncd.service` | Synchronizes the system clock with remote NTP servers. |
| `acpid.service` | Handles ACPI events like power button presses or closing a laptop lid. |
| `vsftpd.service` | A lightweight and secure FTP server daemon. |
| `bat.service` | A systemd service for `bat`, a `cat` clone with syntax highlighting. |

## User-Specific Services

These services run under your user account and are managed with the `--user` flag. They do not require root privileges.

> [!WARNING] Do Not Use `sudo`
> When enabling user services, run the `systemctl` command as your regular user from outside the `chroot` environment post-installation, or from within the `chroot` using a specific command structure. Never use `sudo` with the `--user` flag.

Enable the core user services for audio and session management:

```bash
systemctl --user enable pipewire.socket pipewire-pulse.socket wireplumber.service hypridle.service
```

To enable and immediately start a service, use the `--now` flag. This is useful for services you need right away, like gesture control.

```bash
systemctl enable --now --user libinput-gestures.service
```

### User Services Overview

| Service | Description |
| :--- | :--- |
| `pipewire.socket` | The main socket for the PipeWire multimedia server. |
| `pipewire-pulse.socket` | Provides PulseAudio compatibility for applications. |
| `wireplumber.service` | A session and policy manager for PipeWire. |
| `hypridle.service` | Manages screen idling for the Hyprland compositor. |
| `libinput-gestures.service` | Enables touchpad gestures system-wide. |

## Optional Services

Only enable these services if you have installed the corresponding packages. Enabling a service for a non-existent package will result in an error.

```bash
# Example: Enable the SSH daemon if you installed openssh
systemctl enable sshd.service

# Example: Enable the SDDM display manager
systemctl enable sddm.service
```

### Common Optional Services

| Service | Corresponding Package | Description |
| :--- | :--- | :--- |
| `avahi-daemon.service` | `avahi` | Enables zero-configuration networking (mDNS/DNS-SD). |
| `geoclue.service` | `geoclue` | Provides location services to applications. |
| `iwd.service` | `iwd` | An alternative wireless daemon to `wpa_supplicant`. |
| `man-db.timer` | `man-db` | Periodically updates the man page database cache. |
| `plexmediaserver.service` | `plex-media-server` | Runs the Plex Media Server. |
| `reflector.service` | `reflector` | Updates the mirrorlist on boot. |
| `reflector.timer` | `reflector` | Periodically updates the mirrorlist. |
| `sddm.service` | `sddm` | A modern display manager for X11 and Wayland. |
| `smartd.service` | `smartmontools` | Monitors disk health using S.M.A.R.T. |
| `sshd.service` | `openssh` | Enables remote access via the SSH protocol. |
| `tumbler.service` | `tumbler` | A D-Bus service for generating thumbnail previews. |
| `usbmuxd.service` | `usbmuxd` | Manages services for Apple mobile devices (iPhone, iPad). |

