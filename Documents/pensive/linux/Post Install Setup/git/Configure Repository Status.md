### Step 4: Configure Repository Status

If you were to run `git_dusky status` now, Git would list every single file in your home directory as "untracked." This is unhelpful noise. We must configure this specific repository to hide untracked files by default.

> [!TIP] Local Configuration
> The `--local` flag ensures this setting applies *only* to our dotfiles repository and will not affect any other Git repositories on your system.

```bash
git_dusky config --local status.showUntrackedFiles no
```
Now, running `git_dusky status` will show a clean slate. It will only report on files you explicitly tell it to track.
