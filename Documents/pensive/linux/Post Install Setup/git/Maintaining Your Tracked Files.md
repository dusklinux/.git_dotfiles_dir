### Step 6: Maintaining Your Tracked Files

Whenever you want to add a new file or directory to your backup, simply add its path to `~/.git_dotfiles_list`. For example, to add OBS configuration:

1.  Edit `~/.git_dotfiles_list` and add the new line: `.config/obs/`
2.  Run the workflow:
```bash
git_dotfiles_add_list
git_dotfiles commit -m "Add OBS configuration"
```
