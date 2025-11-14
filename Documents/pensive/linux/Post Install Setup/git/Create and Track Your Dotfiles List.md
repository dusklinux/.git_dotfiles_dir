### Step 5: Create and Track Your Dotfiles List

To avoid adding files one-by-one, we will create a master list of all files and directories we wish to place under version control.

1.  **Create the list file** in your home directory.
```bash
nvim ~/.git_dotfiles_list
```

2.  **Populate the file** with the paths to your desired dotfiles and directories. List one entry per line, with no extra spaces or comments. This file will also track itself.

```plaintext
.config/hypr/
.config/kitty/
.config/mpv/
.config/pacseek/
.config/swaync/
.config/uwsm/
.config/waybar/
.config/wlogout/
.config/waypaper/
.config/wal/
.config/rofi/
.config/xsettingsd/
.config/yazi/
.config/zellij/
.config/zathura/
user_scripts/
notes/
.zshrc
.git_dotfiles_list
.config/starship.toml
.config/mimeapps.list
```

3.  **Create another alias** to easily add all files from this list to the staging area. Open your shell configuration file again:
```bash
nvim ~/.zshrc
```
    And add the following alias:
```bash
alias git_dotfiles_add_list='git_dotfiles add --pathspec-from-file=.git_dotfiles_list'
```
    Remember to `source ~/.zshrc` again after saving.

4.  **Run the new alias** to stage your files for the first time.
```bash
git_dotfiles_add_list
```

5.  **Verify and commit.** Run `git_dotfiles status` to see all your specified files listed under "Changes to be committed." This confirms the system is working. Now, commit them to the repository's history.
```bash
git_dotfiles status
git_dotfiles commit -m "Initial Commit: Fresh Dotfiles Backup"
```
