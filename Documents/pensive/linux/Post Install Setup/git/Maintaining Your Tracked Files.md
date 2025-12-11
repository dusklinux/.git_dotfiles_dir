### Step 6: Maintaining Your Tracked Files

Whenever you want to add a new file or directory to your backup, simply add its path to `~/.git_dusky_list`. For example, to add OBS configuration:

1.  Edit `~/.git_dusky_list` and add the new line: `.config/obs/`
2.  Run the workflow:
```bash
git_dusky_add_list
git_dusky commit -m "Add OBS configuration"
```
