### Step 5: Create and Track Your Dotfiles List

To avoid adding files one-by-one, we will create a master list of all files and directories we wish to place under version control.

1.  **Create the list file** in your home directory.
```bash
nvim ~/.git_dusky_list
```

2.  **Populate the file** with the paths to your desired dotfiles and directories. List one entry per line, with no extra spaces or comments. This file will also track itself.

```plaintext
.config/alacritty/alacritty.toml
.config/btop/btop.conf
.config/cava/config
.config/fastfetch/
.config/fontconfig/
.config/hypr/
.config/kitty/
.config/matugen/config.toml
.config/matugen/templates/
.config/mpv/mpv.conf
.config/nvim/
.config/pacman/makepkg.conf
.config/pacseek/
.config/swaync/
.config/swayosd/
.config/swappy/
.config/uwsm/
.config/waybar/
.config/wlogout/
.config/waypaper/
.config/qt5ct/
.config/qt6ct/
.config/rofi/
.config/systemd/user/swaync.service.d/
.config/xdg-terminals.list
.config/xsettingsd/
.config/yazi/
.config/zellij/
.config/zathura/
.config/autostart/
.zshrc
.git_dusky_list
.config/starship.toml
.config/mimeapps.list
.local/share/errands/data.json
.local/share/rofi-cliphist/pins/
Documents/pensive/Adobe/
Documents/pensive/ai_prompt/
Documents/pensive/Drafts/
Documents/pensive/linux/
Documents/pensive/templates/
Documents/pensive/Windows/
Documents/pensive/z_temp/
Documents/pensive/.obsidian/hotkeys.json
Documents/pensive/.obsidian/appearance.json
Documents/pensive/.obsidian/snippets/
Pictures/wallpapers/dusk_default.jpg
fonts_and_old_stuff/
user_scripts/
README.md
```

3.  **Create another alias** to easily add all files from this list to the staging area. Open your shell configuration file again:
```bash
nvim ~/.zshrc
```
    And add the following alias:
```bash
alias git_dusky_add_list='git_dusky add --pathspec-from-file=.git_dusky_list'
```
    Remember to `source ~/.zshrc` again after saving.

4.  **Run the new alias** to stage your files for the first time.
```bash
git_dusky_add_list
```

5.  **Verify and commit.** Run `git_dusky status` to see all your specified files listed under "Changes to be committed." This confirms the system is working. Now, commit them to the repository's history.
```bash
git_dusky status
git_dusky commit -m "Initial Commit: Fresh Dotfiles Backup"
```
