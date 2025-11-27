# Fresh Arch Linux Installation Checklist

This checklist provides a structured overview of essential tasks to perform after a fresh Arch Linux installation. Follow these steps to configure your system, restore your environment, and set up your applications.

> [!NOTE] Sections with "*Script*" at the top indicate that section has been automated with a script or in process of being written a script for.  

> [!IMPORTANT]+
> Steps to be followed Sequentially. 
> there are going to be a few errorw displayed on the top of the screen by hyprland, ignore those, they will eventually go away as each step is followed to the T

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
*Script*
**OPTIONAL**
- [ ] limit battery temperately (asus tuf f15) (might need to change `BAT1`to see what's available for your laptop for this command to work)

```bash
echo 60 | sudo tee /sys/class/power_supply/BAT1/charge_control_end_threshold
```

---

- [ ] **Restore Dotfiles:** Download the `git` bare repository and deploy the files on your PC [[Restore Backup On a Fresh Install]].

**OPTIONAL**
>[!error]+ Your mouse button will be reversed AFTER RESTORING THE DOTFILES, if you're using a physical mouse. 
>Trackpad not effected. You'll later have the option to set it back to normal configuration in the steps below, or you could do it right now in the following file
>```bash
>nvim ~/.config/hypr/source/input.conf
>```
> change`left_handed = true` to `left_handed = false`

---

**OPTIONAL**
- [ ] If you want to quickly find out how to do something using an existing keybind, hold down `ALT` + `6` for the rofi menu to list the keybind list

---

- [ ] **Link Restored Vault files to Obsidian** : open and link to existing vault. 
- When you open Obsidian for the first time, you'll be prompted with three options. Select "open Folder as Vault (Choose an existing folder of Markdown Files)" this directory should have been populated in ~/Documents/pensive/ after you restored the git files. 

- make sure to NOT create a new vault or sync. select the aforementioned option and navigate to the pensive directory to be selected as source for existing markdown files. 

- You can then copy paste commands from Obsidian on the same PC, no SSHing required

---
*Script*
- [ ] **Set up GNOME Keyring:** Configure GNOME Keyring with PAM for password management. [[Gnome Keyring PAM]]

---
*Script*
- [ ] **Enable UserSession Services**. 

```bash
systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service hypridle.service hyprpolkitagent.service fumon.service gnome-keyring-daemon.service gnome-keyring-daemon.socket hyprsunset
```

---
*Script*
- [ ] configure Reflector config. 
```bash
sudo nvim /etc/xdg/reflector/reflector.conf
```

replace the entire content of the file with this. 
```ini
--save /etc/pacman.d/mirrorlist

# Select the transfer protocol (--protocol).
--protocol https

# Select the country (--country).
# Consult the list of available countries with "reflector --list-countries" and
# select the countries nearest to you or the ones that you trust. For example:
--country India

# Use only the  most recently synchronized mirrors (--latest).
--latest 6

# Sort the mirrors by synchronization time (--sort).
--sort rate 
```

**OPTIONAL**
- [ ] Syncing Pacman Mirrors for faster Download Speeds

if your downloads are currently slow, run this. (**Though Usually not needed**)
```bash
sudo reflector --protocol https --country India --latest 6 --sort rate --save /etc/pacman.d/mirrorlist
```

---
*Script*
- [ ] **pacman-keyring** You must run `pacman-key --init` before first using pacman; the local
keyring can then be populated with the keys of all official Arch Linux packagers with `pacman-key --populate archlinux`.

```bash
sudo pacman-key --init
```

```bash
sudo pacman-key --populate archlinux
```


---
*Script*
**OPTIONAL**
- [ ] enabling better pacman visuals while downloading packages and faster downloads
```bash
sudo nvim /etc/pacman.conf
```

replace the entire content of the file with this. 
```
# /etc/pacman.conf
# See the pacman.conf(5) manpage for option and repository directives
[options]
# The following paths are commented out with their default values listed.
# If you wish to use different paths, uncomment and update the paths.

# Pacman won't upgrade packages listed in IgnorePkg and members of IgnoreGroup
#IgnorePkg   =
#IgnoreGroup =

#NoUpgrade   =
#NoExtract   =

# Misc options
Color
ILoveCandy
VerbosePkgLists
HoldPkg     = pacman glibc
Architecture = auto
CheckSpace
ParallelDownloads = 5
DownloadUser = alpm

# By default, pacman accepts packages signed by keys that its local keyring
# trusts (see pacman-key and its man page), as well as unsigned packages.
SigLevel    = Required DatabaseOptional
LocalFileSigLevel = Optional
#RemoteFileSigLevel = Required

# NOTE: You must run `pacman-key --init` before first using pacman; the local
# keyring can then be populated with the keys of all official Arch Linux
# packagers with `pacman-key --populate archlinux`.

#
# REPOSITORIES
#   - can be defined here or included from another file
#   - pacman will search repositories in the order defined here
#   - local/custom mirrors can be added here or in separate files
#   - repositories listed first will take precedence when packages
#     have identical names, regardless of version number
#   - URLs will have $repo replaced by the name of the current repo
#   - URLs will have $arch replaced by the name of the architecture
#
# Repository entries are of the format:
#       [repo-name]
#       Server = ServerName
#       Include = IncludePath
#
# The header [repo-name] is crucial - it must be present and
# uncommented to enable the repo.
#

# The testing repositories are disabled by default. To enable, uncomment the
# repo name header and Include lines. You can add preferred servers immediately
# after the header, and they will be used before the default mirrors.

#[core-testing]
#Include = /etc/pacman.d/mirrorlist

[core]
Include = /etc/pacman.d/mirrorlist

#[extra-testing]
#Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

# If you want to run 32 bit applications on your x86_64 system,
# enable the multilib repositories as required here.

#[multilib-testing]
#Include = /etc/pacman.d/mirrorlist

[multilib]
Include = /etc/pacman.d/mirrorlist

# An example of a custom package repository.  See the pacman manpage for
# tips on creating your own repositories.
#[custom]
#SigLevel = Optional TrustAll
#Server = file:///home/custompkgs
```
---
*Script*
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
*Script*
- [ ] **Install `paru`:** Set up the `paru` AUR helper. [[Installing an AUR Helper]]

---
*Script*
**OPTIONAL** (Recommanded to circumvent geo blocking of aur url's by the ISP) 
- [ ] **Install Warp and connect to it** or some packages might download excruciatingly slowly [[Warp Cloudflare]]

---
*Script*
**OPTIONAL**
- [ ] Arch extra repo has a history of messing up the packaging for the plugins with hyprland resulting in mismatched headers leading to errors. Enable/disable plugins entirely. [[Toggling Hypr Plugins Manager]]

---
*Script*
**OPTIONAL** but Recommanded
Run this only if you have the plugins enabled and want to use them. 

- [ ] run this once to install and enable hyprland plugins- hyprpm

```bash
hyprpm update
```

- [ ] add this hyprland plugins repo to install from a list of plugins. 

```bash
hyprpm add https://github.com/hyprwm/hyprland-plugins
```

- [ ] enable `hyprexpo` plugin for overview preview of workspaces

```bash
hyprpm enable hyprexpo
```

---
*Script*
- [ ] **Install Core Applications:** Use `paru` to install your essential packages from the repositories and the AUR. [[AUR Packages]]

---
*Script*
- [ ] **Enable Aur packages' services** [[AUR Package services]]

```bash
sudo systemctl enable --now fwupd.service warp-svc.service asusd.service 
```

---
*Script*
- [ ] **Create Directories** for Block device mount points. (only create the ones you have drives for)

```bash
sudo mkdir /mnt/{browser,windows,wdslow,wdfast,media,fast,slow,enclosure}
```

---

- [ ] fix nvim's errors `WARNING {TreeSitter} regex parser is not installed.` `noice.nvim` uses this to highlight regex in the command line nicely. It's a purely visual thing, but fixing it stops the warning.

**The Fix:** Open Neovim and run:

```bash
:TSInstall regex
```

and then intall Mason packages. 
```bash
:Mason
```

Search for the each of these words, and then just hit `i` to install it. 
```ini
clang-format

isort

prettier (for HTML/JS/CSS)

prettierd (keywords: angular, css, flow, graphql, html, json, jsx, javascript, less, markdown, scss, typescript, vue, yaml)

clang-format (for C/C++)

shfmt (for Bash - you might already have this)

stylua (for Lua)

shfmt (The holy grail for Bash scripting)

black (for Python)
```

>[!tip]- These are all the installed ones it should show you after you're done. 
> ```ini
>   Installed
>      ✓ clang-format (keywords: c, c#, c++, json, java, javascript)
> 	 ✓ isort (keywords: python)
> 	 ✓ prettierd (keywords: angular, css, flow, graphql, html, json, jsx, javascript, less, markdown, scss, typescript, vue, yaml)
>     ✓ prettier (keywords: angular, css, flow, graphql, html, json, jsx, javascript, less, markdown, scss, typescript, vue, yaml)
>     ✓ bash-language-server bashls (keywords: bash, csh, ksh, sh, zsh)
>     ✓ black (keywords: python)
>     ✓ clangd (keywords: c, c++)
>     ✓ css-lsp cssls (keywords: css, scss, less)
>     ✓ html-lsp html (keywords: html)
>     ✓ json-lsp jsonls (keywords: json)
>     ✓ lua-language-server lua_ls (keywords: lua)
>     ✓ marksman (keywords: markdown)
>     ✓ pyright (keywords: python)
>     ✓ shfmt (keywords: bash, mksh, shell)
>     ✓ stylua (keywords: lua, luau)
>     ✓ typescript-language-server ts_ls (keywords: typescript, javascript)
> ```

---
**OPTIONAL**
- [ ] **Update `fstab`:** Edit the fstab to reflect the new drives' UUIDs. **fstab requires unlocked UUIDs of block devices** [[fstab reference]] 
- find out UUID's of your relevant disks. boot, home & root are already set. don't touch those in fstab. 

```bash
lsblk -f
```
or 
```bash
sudo blkid
```
or 
```bash
lsblk -o NAME,MODEL,TYPE,SIZE,MOUNTPOINT,FSTYPE,FSVER,UUID,STATE
```

then :
```bash 
sudo nvim /etc/fstab
```

- After making changes to the fstab file, make sure to reload the file into memory. 

```bash
sudo systemctl daemon-reload
```

---

**OPTIONAL**
- [ ] **Update Drive Unlock Script:** Change the UUID in your LUKS/drive unlocking script. **Both, lock and unlock scripts require Locked UUIDs**

- Test if it worked by running the unlock drive script for browser drive. There's an alias for it in the zshrc file, run this. and enter your password, Then check if it correctly mounted at /mnt/browser/

```bash
unlock browser
```

---
*Script*
**OPTIONAL**
- [ ] **Clipboard Persistent/Ephemeral** (Default is Ephemeral)
      if you want Your clipboard contents to persistent through reboots/shutdowns, comment out the line in :

```bash
nvim .config/uwsm/env
```

Comment out this line:

>[!note] export CLIPHIST_DB_PATH="${XDG_RUNTIME_DIR}/cliphist.db"


---
*Script*
- [ ] **Create a symlink** for the service file in user_scripts/waybar/network so the service works. , this is done because service files are looked for in .config/systemd/user/.

```bash
ln -nfs $HOME/user_scripts/waybar/network/network_meter.service ~/.config/systemd/user/network_meter.service
```

and then enable the service 
```bash
systemctl --user enable --now network_meter
```

---
*Script*
- [ ] **Create a symlink** for the service file in user_scripts/battery/battery_notify.service, so the service works. , this is done because service files are looked for in .config/systemd/user/.

```bash
ln -nfs $HOME/user_scripts/battery/notify/battery_notify.service ~/.config/systemd/user/
```

and then enable the service 
```bash
systemctl --user enable --now battery_notify
```


---

(NO LONGER NEEDED, MOVED TO USER CONFIG , SKIP TO NEXT) 
*Script* 
- [ ] Preferred system and terminal fonts.  if you want you could refer to this note for more info [[+ MOC Fonts]] but reading it is not needed, just follow the steps below. 

- **Copy the Pre Configured Configuration file to the  system fonts directory**

```bash
sudo cp ~/fonts_and_old_stuff/setup/etc/fonts/local.conf /etc/fonts/
```

- Refresh the fonts. 

```bash 
sudo fc-cache -fv
```

---
*Script*
## Theming (matugen)

- [ ] First create the following directories for gtk4, btop, wal for firefox. 

```bash
mkdir -p $HOME/.config/gtk-4.0 && mkdir -p $HOME/.config/btop/themes && mkdir -p $HOME/.cache/wal
```

---
*Script*
**Optional**
- [ ] You can place pictures for the wallpaper selector in the wallpapers directory at:- 

place an image in:
```bash
cd $HOME/Pictures/wallpapers/
```

- [ ] **Only for me on asus tuf  f15:** Copy the existing wallpapers folder from the backup media drive and into the local pictures directory 

```bash
cp -r /mnt/media/Documents/do_not_delete_linux/wallpapers ~/Pictures/
```

---

- [ ] Apply a wallpaper. (multiple ways) Option A recommanded. 

- option a: Keybind **Super** + **apostrophe(')**

- option b: with waypaper :- just open waypaper from rofi or terminal and select the wallpapers directory and select any image, or open waypaper with the keybind `Alt + 4` and pick your wallpaper

- option c :or run this command to have matugen generate the colors and place them in required direcotries for the errors to go away 
this command picks an image at random and generates a color pallette for it. 
```bash
matugen image "$(find "$HOME/Pictures/wallpapers" -type f | shuf -n 1)"
```

or pick a specific image manually 
```bash
matugen image $HOME/Pictures/Wallpapers/image.jpg
```

---
*Script*
`Check carefully before changing the following qtct files, these might already be as they should becase they should have been restored from github but sometimes the lines change on a fresh install. And if this step needs to be carried out, only change the lines specified below and nothing else. leave everything as is.`

- [ ] **for qt5ct**  Theming with matugen
open this file

```bash
nvim ~/.config/qt5ct/qt5ct.conf
```

replace these lines at the top of the file with this

```bash
[Appearance]
color_scheme_path=$HOME/.config/matugen/generated/qt5ct-colors.conf
custom_palette=true
style=Fusion
```

- [ ] **for qt6ct**  Theming with matugen
open this file

```bash
nvim ~/.config/qt6ct/qt6ct.conf
```

replace these lines at the top of the file with this

```bash
[Appearance]
color_scheme_path=$HOME/.config/matugen/generated/qt6ct-colors.conf
custom_palette=true
style=Fusion
```

if qt apps still aren't follwing the color pallete of matugen. *sometimes you might need to open `qt5ct` and `qt6ct` and mess around with its settings*

---
*Script*
` This step, again, is usually not needed to be done but check if its needed, by setting a wallpaper with waypaper and see if the theme has switched, open and close the terminal/thunar/or anyother app,  to see if it's switched colors, if not, then preceed with the following:` if themes did switch sucessfuly, this step is not required. 

- [ ] Might need to recreate the config file for waypaper because sometimes it's got issues when it's restored from git. so delete the entire file, open waypaper> change any setting> when a new config is auto created, edit it just the post_command line to include the command. 

```bash
rm ~/.config/waypaper/config.ini && waypaper
```

```bash
nvim ~/.config/waypaper/config.ini
```

```ini
post_command = matugen --mode dark image $wallpaper
```

--- 
*Script*
**OPTIONAL**
DARK/LIGHT THEME SWITCH

- [ ] to change the color scheme from dark to light or the other way around. 
you can left/right click the color theme toggle on the waybar. (might need to click it multiple times for theme to switch or just click it once and then apply a wallpaper with waypaper or `super + apostrophe(')`) , If waybar is not toggled, you can open it with `Alt + 9` and close it with `Alt + 0`

## or
	(not recommended because this is not persistent and it doesnt change it for matugen colors)
- [ ] manually open nwg-loog and set the `color scheme` to either `prefer dark` or `prefer light` if it doesn't apply automatically when switching wallpaper and triggering the matugen command

---

**OPTIONAL**

- [ ] Obsidian themeing (matugen)
Obsidian doesn't usually respect matugen theming on its own so you need to manually do two things. 
first, make sure you've set the appropriate colro scheme for your current theme - dark/light from the waybar. 

then open obsidian's settings > Appearance > Scroll to the bottom to `CSS snippets`> Toggle on the `matugen-theme` option, and not the other one (if it exists). if you toggle on both, sometimes they will both be toggled off the next time you open Obsidian

---
*Script*
- [ ] Set over all animations with just one click. 
hold down `ALT` + `SUPER(windows key)` + `A`  after you hold down all these at once, rofi menu will show up for you to select from a list of animations. pick anyone. (`fluid` is recommended but pick the one you like.)

---
*Script*
- [ ] **Sound notify when usb plugin/disconnect** [[Configure udev auditory notify usb plugin]]

---
*Script*
- [ ] Set kitty as your defualt terminal. 
```bash
nvim ~/.config/xdg-terminals.list
```
and then paste this in it. just this. 
```ini
kitty.desktop
```

---
*Script*
**OPTIONAL**
- [ ] block attention sucking sites. 

```bash
sudo nvim /etc/hosts
```

> [!NOTE]- Hosts file blocking
> ```ini
> 0.0.0.0 instagram.com
> 0.0.0.0 www.instagram.com
> 0.0.0.0 facebook.com
> 0.0.0.0 www.facebook.com
> 0.0.0.0 m.facebook.com
> 0.0.0.0 x.com
> 0.0.0.0 www.x.com
> 0.0.0.0 twitter.com
> 0.0.0.0 www.twitter.com
> 0.0.0.0 twitch.tv
> 0.0.0.0 www.twitch.tv
> 0.0.0.0 kick.com
> 0.0.0.0 www.kick.com
> 0.0.0.0 www.reddit.com
> ```

---

*Script*
**OPTIONAL** 
- [ ] *Optional* : Link Browser data to existing drive (only do if you have a separate browser drive where you want for browser data to be stored)

- Do Not Open Firefox until all steps are done (close it if it's open)

- First Completely Wipe Firefox Data on your current setup. 

- Removes the primary Firefox profile data
- Removes the parent .mozilla directory, catching all related data
- Clears the application cache for Firefox

```bash
rm -rf ~/.mozilla/firefox/ ~/.mozilla ~/.cache/mozilla
```

create the .mozilla directory that will then be simlinked (make sure the drive is mounted and created first)

```bash
mkdir -p /mnt/browser/.mozilla
```

This command links the `.mozilla` folder from an external drive mounted at `/mnt/browser/.mozilla` to the location where Firefox expects to find it in the user's home directory.

```bash
sudo ln -nfs /mnt/browser/.mozilla ~/.mozilla
```

---

**OPTIONAL**
- [ ] Firefox themeing (if you use firefox.) 
install the extention `Pywalfox` from the mozilla store. and then open the plugin and select `Fetch Pywal colors`

---
*Script*
**OPTIONAL**

- [ ] **Comment out anything beyond  the end line of zshrc, if there is anything there,  to speed up your terminal:** :- 

```bash
nvim ~/.zshrc
```

>[!note]- Comment out beyond this part
> ===========================
> End of ~/.zshrc
> ============================

---
*Script*
- [ ] *Optional*: **TLP config** : copy the tlp config to /etc/tlp.conf [[+ MOC tlp config]]

---
*Script*
- [ ] *Optional*:**Create Disk Swap** [[Disk Swap]] 
      zram swap should already have been created during installation process, you can check if zram block drives are active. usually zram0 and zram 1 if you followed the instruction during arch install. 

	If you Still want more swap and can spare some disk storage for it, you can create disk swap, it's recommanded to create one if you have =<4gb of ram. 

---
*Script*
- [ ] *Optional*: **Configure Auto-Login:** Set up automatic login on TTY1. [[+ MOC Auto Login]]

---
*Script*
- [ ] *Optional*:**Configure swapiness for zram** Optimal if you have sufficiant ram ie equal to or more than 4GB [[Optimizing Kernel Parameters for ZRAM]]

---
*Script*
- [ ] *Optional*: **Configure Power Key:** Define the system's behavior when the power key is pressed. [[Power Key Behaviour]]

---
*Script*
**OPTIONAL**
- [ ] Fix logratate by uncommenting size and compress in 

```bash
sudo nvim /etc/logrotate.conf
```

---
*Script*
**OPTIONAL**
- [ ] fix being locked out if you enter incorrect password [[Incorrect Password Attempt Timeout]]

---

**OPTIONAL**
- [ ] Run Jdownloader once to let it downlaod all the files it needs to update itself. 
`just open it with rofi or wofi` and click yes if there's an update. 

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

> [!error]+ Comment OUT Everything Beyond This Line
> #-------------------------NVIDIA-------------------------------
> #COMMENT OUT ANY SET ENVIRONMENT VARIABLE IF YOU DONT HAVE NVIDIA
> #--------------------------------------------------------------

---

- [ ] Comment OUT this variable If you only have integrated GPU i.e no NVIDIA

```bash
nvim ~/.config/uwsm/env-hyprland
```

> [!error]+ Comment OUT this line
> export AQ_DRM_DEVICES=/dev/dri/card1

---
*Script*
**HYPRLAND CONFIG** changes. 

```bash
nvim ~/.config/hypr/hyprland.conf
```

 - [ ] This line is to run a script for configuring asus profiles for Asus specific hardware and for changing keyboard color along with fan control. 
 
 ```bash
 nvim .config/hypr/source/keybinds.conf
 ```


>[!error]+ Comment out Asus specific Script
>bindl = , XF86Launch3, exec, kitty -e sudo ~/user_scripts/asus/asus-control.sh

- [ ] Comment OUT the custom key-binds for changing refresh rate that are specific to asus laptops with 144 hz with  `Alt+6` and `Alt+7`.

> [!error]+ Comment OUT these two lines
> bind = ALT, 6, exec, hyprctl keyword monitor eDP-1,1920x1080@60,0x0,1.6
> bind = ALT, 7, exec, hyprctl keyword monitor eDP-1,1920x1080@144,0x0,1.6

- [ ] IF you dont have an nvidia GPU, Comment out this and replace it with this. 

> [!error]+ Comment out these lines 
>```ini
>#FASTERWHISPER TTS
>bind = $mainMod SHIFT, I, exec, ~/user_scripts/faster_whisper/faster_whisper_sst.sh
>
>#Nvidia Parakeet
>bind = $mainMod, I, exec, ~/user_scripts/parakeet/parakeet.sh
>```  

> [!tip]+ And add this line instead
> ```ini
> bind = $mainMod, I, exec, ~/user_scripts/faster_whisper/faster_whisper_sst.sh
>```


---
*Script*
- [ ] **Configure Monitor Output:** Here one line needs to be Un-Commented and another Commented out. 

```bash
nvim .config/hypr/source/monitors.conf
```

> [!tip]+ Un-Comment this line to auto detect Your Screen configuration
> #monitor=,preferred,auto,auto  # Generic rule for most laptops

> [!error]+ Comment OUT this line (specifically for 144 hz asus laptop)
> monitor=eDP-1,1920x1080@60,0x0,1.6 # Specific for ASUS TUF F15 Laptop

---
*Script*
- [ ] Mouse left/right click buttons are swapped by default, switch them back to normal. 

```bash
nvim .config/hypr/source/input.conf
```

> [!error]+ Comment OUT this line 
> left_handed = true


---
*Script*
- [ ] for changing default file manager from yazi to thunar. 

> [!tip]+ to change yazi to thunar as default
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
*Script*
Dont do this, reserach what your specific gpu has.  (skip this)
- [ ] Comment out this line from mpv's config if you don't have an av1 decoder. can be checked by running `vainfo`

```bash
nvim ~/.config/mpv/mpv.conf
```

> [!error]+ Comment out this part
> hwdec-codecs=vp9,h264,hevc,av1


---
*Script*
- [ ] Delete the override service file for swaync to force it to use the intel GPU, For laptops with both dGPU and iGPU, for some reason swaync uses the dGPU by default which increases powerusage, IF you only have one GPU delete this file.

```bash
rm -rf ~/.config/systemd/user/swaync.service.d/gpu-fix.conf
```

---

## Only for Asus tuf f15 

- [ ] **Asus misconfiguration for asusd D-bus:** :- follow the note for it if you have an asus laptop. [[Asusd Dbus Misconfiguration]]

- [ ] *Optional* **Copy the asusd directory for asusrelated configuration to /etc:** :- 

```bash
sudo cp ~/fonts_and_old_stuff/setup/etc/asusd /etc/
```

---

- [ ] make sure to uncomment this line if it's commented to allow for the nvidia gpu to sleep or else xwayland will keep it awake and prevent d3 state. 

```bash
nvim ~/.config/uwsm/env-hyprland
```

> [!tip]+ UN-Comment this line
> ```ini
>export AQ_DRM_DEVICES=/dev/dri/card1
>```

> [!error]+ No longer used because hyprland no longer uses wl-roots. it uses aquamarien
> this should be commented in 
> ```bash
> nvim ~/.config/uwsm/env
> ```
>```
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


---

- [ ] **Configure Thunar:** Set up the right-click "Open Terminal Here" custom action.

>Thunar > Edit > Configure Custom Actions... > Open Terminal Here > Edit the Currenctly selected action > delete everything in the `Command:` box and type your terminal's name eg kitty. 

---
*Script*
### 5. Services & Networking

Enable essential background services and disable ones you don't need.

- [ ] **Optimize Network Services:** Disable any extra NetworkManager services that are not required. [[Network Manager]]

```bash
sudo systemctl disable NetworkManager-wait-online.service
```

---
*Script*
- [ ] **Set up FTP:** Configure your FTP client or server as needed. [[+ MOC FTP]]

---
*Script*
### Application Configuration

- [ ] terminal tldr update for commands example. 

```bash
tldr --update
```

---
**OBSELETED** (SKIP this)
- [ ] **`firefox`:** Apply your custom `userChrome.css` for the side-panel modifications., hardware acceleration and smoothscrooling and other stuff refer to [[+ MOC Firefox]]

---
*Script*
- [ ] **`spotify`:** without adds script [[Spotify]]

---

- [ ] **Obsidian** download `hider`, `copilot` plugins and also downlaod the `primary` theme. 

---
*Script*
### 7. Re-Link exisiting github repo to continue backing up to it. 

- [ ] Follow these steps after you've already checked out and restored all the files from the github repo  [[Relink to my existing github repo for backup after Fresh Install]]

or

- [ ] create a new github repo to start backing up. [[git_bare_repo_setup]]

---
*Script*
Free up storage by clearing package cache for paru and pacman 
  
- [ ] **Free up storage by clearing pacman Cache**

```bash
sudo pacman -Scc
```

- [ ] **Free up storage by clearing paru Cache**
```bash
paru -Scc
```

---
