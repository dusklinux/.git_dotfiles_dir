# Fresh Arch Linux Installation Checklist

This checklist provides a structured overview of essential tasks to perform after a fresh Arch Linux installation. Follow these steps to configure your system, restore your environment, and set up your applications.

> [!IMPORTANT]+
> Steps to be followed Sequentially.

### 1. Core System & Environment Setup

This phase focuses on critical system files, user environment, and restoring your base configuration.

- [ ] **Login with uwsm** 

```bash
exec uwsm start hyprland
```

- [ ] **Connect to the internet**: Depending on what you use, (ie tethering does not usually need to be setup) [[Network Manager]]

---

- [ ] *Optional but recommended* There are 2 commands that are long and complex, to prevent typos, it's recommended to copy paste them by SSH'ing into the PC from a phone or another pc, for referenced- not needed to refer to [[SSH]]

```bash
sudo systemctl start sshd && ip a
```

---

- [ ] **Restore Dotfiles:** Download the `git` bare repository and deploy the files on your PC [[Restore Backup On a Fresh Install]].

---

- [ ] **Link Restored Vault files to Obsidian** : open and link to existing vault. 
- When you open Obsidian for the first time, you'll be prompted with three options. Select "open Folder as Vault (Choose an existing folder of Markdown Files)" this directory should have been populated in ~/Documents/pensive/ after you restored the git files. 

- make sure to NOT create a new vault or sync. select the aforementioned option and navigate to the pensive directory to be selected as source for existing markdown files. 

- You can then copy paste commands from Obsidian on the same PC, no SSHing required

---

- [ ] **Set up GNOME Keyring:** Configure GNOME Keyring with PAM for password management. [[Gnome Keyring PAM]]

---

- [ ] **Enable UserSession Services**. 

```bash
systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service hypridle.service hyprpolkitagent.service
```

---

- [ ] **Set Default Shell:** Change the default shell from `bash` to `zsh` 
- To make Zsh your login shell, use the `chsh` (change shell) command and then enter your Password

```bash
chsh -s $(which zsh)
```

> [!IMPORTANT]-
> For the change to take full effect, you must **log out and log back in**. Simply opening a new terminal window is not enough.

- [ ] **Reboot** :

```bash
systemctl reboot
```

After logging back in, you can verify that your shell has been changed:

```bash
echo $SHELL
```

The output should be `/bin/zsh` or `/usr/bin/zsh`.

---

- [ ] **Install `paru`:** Set up the `paru` AUR helper. [[Installing an AUR Helper]]

---

- [ ] **Install Warp and connect to it** or some packages might download excruciatingly slowly [[Warp Cloudflare]]

---

- [ ] **Install Core Applications:** Use `paru` to install your essential packages from the repositories and the AUR. [[AUR Packages]]

---

- [ ] **Enable Aur packages' services** [[AUR Package services]]

```bash
sudo systemctl enable --now fwupd.service warp-svc.service asusd.service 
```

---

- [ ] **Setup Cursor**  : after installing the cursor and icons, enter this command to apply the theme.  

For bibata-modern-classic with 18 cursor size. (change the size to your liking)

```bash 
hyprctl setcursor Bibata-Modern-Classic 18
```

- for enabling icon theme open nwg-look aka gtk settings and navigate to the `Icon theme` tab to select the theme and apply it 

---

- [ ] Run Jdownloader once to let it downlaod all the files it needs to update it self. 
`just open it with rofi or wofi`

---

- [ ] **Create Directories** for Block device mount points. (only create the ones you have drives for)

```bash
sudo mkdir /mnt/{browser,windows,wdslow,wdfast,media,fast,slow,enclosure}
```

---

- [ ] **Update `fstab`:** Edit the fstab to reflect the new drives' UUIDs. **fstab requires unlocked UUIDs of block devices** [[fstab reference]] 
- find out UUID's of your relevant disks. boot, home & root are already set. don't touch those in fstab. 

```bash
lsblk -f
```
or 
```bash
sudo blkid
```

```bash 
sudo nvim /etc/fstab
```

- After making changes to the fstab file, make sure to reload the file into memory. 

```bash
sudo systemctl daemon-reload
```

---

- [ ] **Update Drive Unlock Script:** Change the UUID in your LUKS/drive unlocking script. **Both, lock and unlock scripts require Locked UUIDs**

- Test if it worked by running the unlock drive script for browser drive. There's an alias for it in the zshrc file, run this. and enter your password, Then check if it correctly mounted at /mnt/browser/

```bash
unlock browser
```

---

- [ ] *Optional* : Link Browser data to existing drive (only do if you have a seperate browser drive where you have exisitng browser data stored)

- Do Not Open Firefox until all steps are done (close it if it's open)

- First Completely Wipe Firefox Data on your current setup. 

- Removes the primary Firefox profile data
- Removes the parent .mozilla directory, catching all related data
- Clears the application cache for Firefox

```bash
rm -rf ~/.mozilla/firefox/ ~/.mozilla ~/.cache/mozilla
```

This command links the `.mozilla` folder from an external drive mounted at `/mnt/browser/.mozilla` to the location where Firefox expects to find it in the user's home directory.

```bash
sudo ln -s /mnt/browser/.mozilla ~/.mozilla
```

---

- [ ] **Comment out anything beyond  the end line of zshrc, if there is anything there,  to speed up your terminal:** :- 

```bash
nvim ~/.zshrc
```

>[!note]- Comment out beyond this part
> ===========================
> End of ~/.zshrc
> ============================

---

- [ ] *Optional*: **TLP config** : copy the tlp config to /etc/tlp.conf [[+ MOC tlp config]]

---

- [ ] *Optional*:**Create Disk Swap** [[Disk Swap]] 

---

- [ ] *Optional*: **Configure Auto-Login:** Set up automatic login on TTY1. [[+ MOC Auto Login]]

---

- [ ] *Optional*:**Configure swapiness for zram** Optimal if you have sufficiant ram ie equal to or more than 4GB [[Optimizing Kernel Parameters for ZRAM]]

---

- [ ] *Optional*: **Configure Power Key:** Define the system's behavior when the power key is pressed. [[Power Key Behaviour]]

---

- [ ] Fix logratate by uncommenting size and compress in 

```bash
sudo nvim /etc/logrotate.conf
```

---

- [ ] fix being locked out if you enter incorrect password [[Incorrect Password Attempt Timeout]]

---

- [ ] run this once to install and enable hyprland plugins- hyprpm

```bash
hyprpm update
```


---
- [ ] add this hyprland plugins repo to install from a list of plugins. 

```bash
hyprpm add https://github.com/hyprwm/hyprland-plugins
```

---

- [ ] enable `hyprexpo` plugin for overview preview of workspaces

```bash
hyprpm enable hyprexpo
```

---

- [ ] **Fix Gnome apps opening two instances of nautilus** and other apps by following the following instructions [[Gnome Apps opening Twice]]

---

- [ ] **Reboot** 

```bash
systemctl reboot
```

---

### 2. Very Important to REMOVE the following configs if you have a PC other than Asus Tuf f15 2022 or a pc without a Dedicated GPU like NVIDIA or AMD

Fine-tune your Hyprland compositor and shell environment. These steps are often machine-specific.

> [!CAUTION]+
> The following steps involve hardware-specific settings. Adjust them carefully based on whether you are on Asus tuf 15 or another pc  and what GPU you are using.

## For non Asus tuf f15 laptops

**Clean Environment Variables:**

- [ ] Comment OUT any and all environment variable under the Nvidia section in the uwsm env file. 

```bash
nvim ~/.config/uwsm/env
```

> [!tip]- Comment OUT Everything Beyond This Line
> #-------------------------NVIDIA-------------------------------
> #COMMENT OUT ANY SET ENVIRONMENT VARIABLE IF YOU DONT HAVE NVIDIA
> #--------------------------------------------------------------

---

- [ ] Comment OUT this variable If you only have integrated GPU i.e no NVIDIA

```bash
nvim ~/.config/uwsm/env-hyprland
```

> [!tip]- Comment OUT this line
> export AQ_DRM_DEVICES=/dev/dri/card1

---

**HYPRLAND CONFIG** changes. 

```bash
nvim ~/.config/hypr/hyprland.conf
```

 - [ ] This line is to run a script for configuring asus profiles for Asus specific hardware and for changing keyboard color along with fan control. 
 
>[!note]- Comment out Asus specific Script
>bindl = , XF86Launch3, exec, kitty -e sudo ~/user_scripts/asus/asus-control.sh


- [ ] **Configure Monitor Output:** Here one line needs to be Un-Commented and another Commented out. 

> [!tip]- Un-Comment this line to auto detect Your Screen configuration
> #monitor=,preferred,auto,auto  # Generic rule for most laptops

> [!tip]- Comment OUT this line (specifically for 144 hz asus laptop)
> monitor=eDP-1,1920x1080@60,0x0,1.6 # Specific for ASUS TUF F15 Laptop

- [ ] Mouse left/right click buttons are swapped by default, switch them back to normal. 

> [!tip]- Comment OUT this line 
> left_handed = true

- [ ] Comment OUT the custom key-binds for changing refresh rate that are specific to asus laptops with 144 hz with  `Alt+6` and `Alt+7`.

> [!tip]- Comment OUT these two lines
> bind = ALT, 6, exec, hyprctl keyword monitor eDP-1,1920x1080@60,0x0,1.6
> bind = ALT, 7, exec, hyprctl keyword monitor eDP-1,1920x1080@144,0x0,1.6

- [ ] Comment out this and replace it with this. 

> [!tip]- Comment out these lines 
> ```ini
>#FASTERWHISPER TTS
bind = $mainMod SHIFT, I, exec, ~/user_scripts/faster_whisper/faster_whisper_sst.sh
>
>#Nvidia Parakeet
>bind = $mainMod, I, exec, ~/user_scripts/parakeet/parakeet.sh
>```  

> [!tip]- And add this line instead
> ```ini
> bind = $mainMod, I, exec, ~/user_scripts/faster_whisper/faster_whisper_sst.sh
>```

- [ ] for changing file manager from yazi to thunar. 

> [!tip]- to change yazi to thunar as default
>replace this line `$fileManager = yazi` with 
>```ini
>$fileManager = thunar
>```
>and then replace this line `bind = $mainMod, E, exec, kitty -e $fileManager` with 
>```ini
>bind = $mainMod, E, exec, $fileManager
>```
>and then finally run this command
>```bash
>xdg-mime default thunar.desktop inode/directory
>```
> explination of the command
> By running this command, you are telling your system, "From now on, whenever you are asked to 'open' a directory, use the application defined in thunar.desktop." This change is saved specifically for your user in the ~/.config/mimeapps.list file.
> xdg-mime default: This is the command to set a default application.
>thunar.desktop: This is the standard desktop entry for the Thunar application. The system looks for this file in /usr/share/applications/ to get information about how to run Thunar.
>inode/directory: This is the official MIME type for a folder or directory.

---

- [ ] **Comment out Asus service for keybaord auto theme color pywal16 in :** :- 

```bash
nvim ~/user_scripts/waypaper/wallpaper_update.sh
```

> [!tip]- Comment out this part
> "~/user_scripts/asus/asus_keyboard_color_pywal16.sh"

---

- [ ] Comment out this line from mpv's config if you don't have an av1 decoder. can be checked by running `vainfo`

```bash
nvim ~/.config/mpv/mpv.conf
```

> [!note]- Comment out this part
> hwdec-codecs=vp9,h264,hevc,av1


---

- [ ] Delete the override service file for swaync to force it to use the intel GPU, For laptops with both dGPU and iGPU, for some reason swaync uses the dGPU by default which increases powerusage, IF you only have one GPU delete this file.

```bash
rm -rf ~/.config/systemd/user/swaync.service.d/gpu-fix.conf
```

---

## Only for Asus tuf f15 

- [ ] **Asus misconfiguration for asusd D-bus:** :- follow the note for it if you have an asus laptop. [[Asusd Dbus Misconfiguration]]

- [ ] *Optional* **Copy the asusd directory for asusrelated configuration to /etc:** :- 

```bash
sudo cp ~/notes/setup/etc/asusd /etc/
```

- [ ] copy the decay green folder from the media drive to the local drive. 

```bash
cp -r /mnt/media/Documents/do_not_delete_linux/themes/Decay-Green ~/.local/share/themes/
```

for root
```bash
sudo cp -r /mnt/media/Documents/do_not_delete_linux/themes/Decay-Green /usr/share/themes/
```
- [ ] Copy the Wallpaper folder into local pictures directory 

```bash
cp -r /mnt/media/Documents/do_not_delete_linux/wallpapers ~/Pictures/
```

- [ ] make sure to uncomment this line if it's commented to allow for the nvidia gpu to sleep or else xwayland will keep it awake and prevent d3 state. 

```bash
nvim ~/.config/uwsm/env
```

> [!tip]- UN-Comment this line
> ```ini
> export WLR_DRM_DEVICES="/dev/dri/card1"
>```
---

### 3. (Optional) Package Management & Software Installation

- [ ] **Install Tools:**
    - [ ] Install `ollama`. [[+ MOC Ollama]]
    - [ ] Install `faster-whisper`. [[Faster Whisper]]
    - [ ] Install Nvidia `parakeet` [[Parakeet]]
	- [ ] Install `kokoro` [[Kokoro Rust CPU]]
	- [ ] Install `kokoro` [[Kokoro GPU]]
	- [ ] Install `DaVinci Resolve` [[DaVinci Resolve]]
	- [ ] Install `Steam, wine, lutris` [[Gaming]]
	- [ ] Install `Waydroid` :- Android container. lightweight. [[+ MOC Waydroid]]

---

### 4. Theming & Desktop Customization

This section covers the visual setup of your desktop, from dynamic colors to fonts and terminal appearance.

- [ ] **Install `pywal16`:** Install the dynamic theming engine. [[pywal16]]

```bash
pipx install pywal16
```

---

- [ ] **Create a symlink** for the service file in user_scripts/waybar/network so the service works. , this is done because service files are looked for in .config/systemd/user/.

```bash
ln -s $HOME/user_scripts/waybar/network/network_meter.service ~/.config/systemd/user/network_meter.service
```

and then enable the service 
```bash
systemctl --user enable --now network_meter
```

---

- [ ] **Generate Initial Theme:** Run `wal` with your desired wallpaper to create the first color palette. Eg: command

```bash
wal -i Pictures/wallpapers/GR3bOIjWMAAFSCZ.jpg
```

---

- [ ] **Configure Kitty Theme:** Edit `kitty.conf` to source its colors directly from `pywal`'s cache. [[General Theming]]

---

- [ ] *Optional* : preferred system and terminal fonts.  Not needed but if you want you could refer to this note for more info [[+ MOC Fonts]]
- **Copy the Pre Configured Configuration file to the  system fonts directory**

```bash
sudo cp ~/notes/setup/etc/fonts/local.conf /etc/fonts/
```

- Refresh the fonts. 

```bash 
sudo fc-cache -fv
```

---

- [ ] **Configure Thunar:** Set up the right-click "Open Terminal Here" custom action.

>Thunar > Edit > Configure Custom Actions... > Open Terminal Here > Edit the Currenctly selected action > delete everything in the `Command:` box and type your terminal's name eg kitty. 

---

### 5. Services & Networking

Enable essential background services and disable ones you don't need.

- [ ] **Optimize Network Services:** Disable any extra NetworkManager services that are not required. [[Network Manager]]

```bash
sudo systemctl disable NetworkManager-wait-online.service
```

---

- [ ] **Set up FTP:** Configure your FTP client or server as needed. [[+ MOC FTP]]

---

### 6. Application Configuration

Finalize the setup for individual applications.

- [ ] **`mpv`:** Setup your MPV player to be controlled with a keybind. (keybind already set in hyprland conf) , not needed but for more info refer to [[MPV]]


```bash
sudo pacman -S --needed mpv-mpris
```

- Create the `scripts` directory:

```bash
mkdir -p ~/.config/mpv/scripts
```

- Create the symbolic link:

```bash
ln -s /usr/lib/mpv/scripts/mpris.so ~/.config/mpv/scripts/
```

---

- [ ] terminal tldr update for commands example. 

```bash
tldr --update
```

---
- [ ] Neovim NVChad 

```bash
git clone https://github.com/NvChad/starter ~/.config/nvim && nvim
```

---

- [ ] **`firefox`:** Apply your custom `userChrome.css` for the side-panel modifications., hardware acceleration and smoothscrooling and other stuff refer to [[+ MOC Firefox]]

---

- [ ] **`spotify`:** without adds script [[Spotify]]

---

- [ ] **Obsidian** download `hider`, `copilot` plugins and also downlaod the `primary` theme. 

---
### 7. Re-Link exisiting github repo to continue backing up to it. 

- [ ] Follow these steps after you've already checked out and restored all the files from the github repo  [[Relink to my existing github repo for backup after Fresh Install]]

or

- [ ] create a new github repo to start backing up. [[git_bare_repo_setup]]

---

- [ ] **Free up storage by clearing pacman Cache**

```bash
sudo pacman -Scc
```

---
