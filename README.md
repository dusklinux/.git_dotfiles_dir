Great News! the entire thing has been semi automated with scripts. you still need to enter a few commands but they are about 99% less in number than before. the commands you need to run are merely to clone the github repo and run the scripts.

These dotfiles are configured for intel with or without nvidia. but you can just as easily install it on amd, with a few minor changes to the packages installer script `004_package_installation.sh` . replace intel specific packages with amd.
If you have an amd gpu/cpu. you're going to have to research packages specific to your cpu/gpu. also make sure to include the microcode for amd.

🌆 Dusk Linux Dotfiles

Hi there! Welcome to my personal configuration setup.

This repository is the result of about 8 months of tinkering, breaking, fixing, and polishing. It's a true labor of love. I wanted to design something that feels as easy to install as a "standard" distribution, but with the power and minimalism of Arch Linux.


⚠️ A Friendly Disclaimer

Since this entire system is built and maintained by just one person (me!), it might not be quite as polished as a corporate OS. Every part of this setup was created from scratch, though I did borrow and tune a few clever files from the community over the months to fit this specific vision.

The steepest learning curve of this will be the keybinds, I've put a lot of thought into making it make sense but I understand what might be intuitive for me may not be so for you. So feel free to configure your own keybinds if you dont like something. You can press `SUPER`+ `SPACE` to list all the preconfigured keybinds and invoke them right from the rofi menu. you dont need to remember everything, as you use the system, you'll eventually remember the ones you use the most.

🚀 Installation Guide

While this should theoretically work on any already preconfigured arch based system, i can't assure it will work, In my experience, installing it on top of omarchy did work but had a few fixable issues, nothing too bad. Gemini is your friend if you hit a wall. A clean install is highly recommended to minimize curve balls. 

Step 1: The Base System

To get the smoothest experience, I highly recommend starting with the official Arch Linux ISO and starting fresh with the preconfigured/automated hyprland install.
USE BTRFS instead of any other format, it's superior in everyday and it has matured. The zstd compression alone is worth it, not to mention CoW to prevent corruption. And Snapshotting capabilities. 

Also use gurb, You can obviously chose to use other bootloaders but the scirpt is optimized for grub, plus to keep these dotfiles widely supporting of hardware, grub is the obvious choice since it supports both uefi/legacy bios.

Download the ISO from the Arch Linux website.

Boot it up and run the archinstall script.

Under Desktop options, make sure to select Hyprland.

Why this method?
While you can do a minimal setup and run the scripts from the TTY, starting with the Hyprland profile via archinstall makes the process much faster and ensures fewer hiccups. If you go the TTY route, one or two scripts might fail, don't worry, you can re run them after you boot into the environment.

Step 2: deploy the Dotfiles

Once you are logged into your new system, open your terminal. We are going to use a specific Git method (bare repository) to drop the files exactly where they need to go.

1. Download the repository:
```bash
git clone --bare --depth 1 https://github.com/dusklinux/dusky.git $HOME/dusky
```

2. Checkout (Deploy) the files:
```bash
git --git-dir=$HOME/dusky/ --work-tree=$HOME checkout -f
```

> Note: The  f flag stands for force. It will overwrite existing configuration files in your home directory with these dotfiles.

🎻 The Orchestra Script

This setup relies on a parent script I call ORCHESTRA. It acts as a conductor, managing about ~50 subscripts that handle everything from theming to system services to package isntallation.

run it with this command. 
```bash
$HOME/user_scripts/setup_scripts/ORCHESTRA.sh
```

> Note: all the subscripts it runs are located in $HOME/user_scripts/setup_scripts/scripts/ , if a subscript fails, you can run it individually, or throw it into gemini/gpt to have it figure out why it's not working on your system. 

⏳ Time Expectation

Grab a coffee (or two). The entire auto install takes anywhere from 30 minutes to an hour, depending on your internet connection and CPU speed.

Why? We use paru to manage packages, and some of them need to be compiled from source.

🔧 Troubleshooting

If you see a red line or a script fails, don't panic! It happens. The installation is robust enough to keep going even if one subscript trips up.

Tip: If a specific script fails, take a look at the file content. If you're stuck, copy the script into ChatGPT or an LLM, it usually does a great job of explaining exactly what went wrong.

You can usually fix the specific issue and run that single script again manually.

↺ Reset / Restore

If you've messed around with the configurations and just want to get back to the clean state of this repo (or if you want to remove the git tracking for these dotfiles), run:
```bash
rm -rf ~/dusky
```

> Warning: This removes the local git history for the dotfiles. If you re run the clone command after this, it will revert any personal changes you've made to the config files.

Enjoy the setup! I hope it serves you as well as it has served me.
