### Step 3: Create a Custom `git_dusky` Alias

It would be intolerably cumbersome to specify the repository location for every command. To solve this, we will create a shell alias that acts as a proxy to Git, pre-configured to work with our dotfiles repository.

1.  **Open your shell's configuration file.** The example uses `zsh`; if you use Bash, edit `~/.bashrc` instead.

```bash
nvim ~/.zshrc
```

2.  **Add the following alias.** This is the most critical step for usability.

```bash
# Alias for managing dotfiles with a bare git repo
alias git_dusky='/usr/bin/git --git-dir=$HOME/dusky/ --work-tree=$HOME'
```

*   `--git-dir=$HOME/dusky/`: Tells Git where to find its database (our bare repository).
*   `--work-tree=$HOME`: Tells Git that the working directory for this repository is your home directory.

3.  **Apply the changes** to your current shell session.

```bash
source ~/.zshrc
```
