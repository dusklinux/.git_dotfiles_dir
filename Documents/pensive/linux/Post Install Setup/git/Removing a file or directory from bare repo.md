If you no longer want to track a file or directory, you must first remove it from `~/.git_dusky_list`. Then, use the following commands to remove it from the Git index.

- **To remove a single file:**

  ```bash
  git_dusky rm --cached path/to/file
  ```

- **To remove an entire directory: **
  ```bash
  git_dusky rm -r --cached path/to/directory/
  ```
  **Example:**
  ```bash
  git_dusky rm -r --cached .config/Thunar/
  ```

> [!tip] Add the force flag if it gives you problems **-f**
>
> ```bash
> eg git_dusky rm -f --cached path/to/file
> ```
>
> ```bash
> git_dusky rm -r -f --cached path/to/directory/
> ```

After running the `rm` command, commit the change to finalize its removal from version control: `git_dusky commit -m "Stop tracking Thunar config"`.
