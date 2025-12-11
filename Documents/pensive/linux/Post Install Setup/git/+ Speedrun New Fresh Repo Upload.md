
### for detailed explination of the commands follow [[git_bare_repo_setup]]

---
- [ ] 1 
```bash
git config --global user.name "dusk"
```
- [ ] 2
```bash
git config --global user.email "dusk1@myyahoo.com"
```
- [ ] 3
```bash
git config --global init.defaultBranch main
```
- [ ] 4
```bash
git init --bare $HOME/dusky
```
- [ ] 5
```bash
git_dusky config --local status.showUntrackedFiles no
```
- [ ] 6
```bash
git_dusky_add_list
```
- [ ] 7
```bash
git_dusky status
git_dusky commit -m "Initial Commit: Fresh Dotfiles Backup"
```
- [ ] 8
#### Create an Empty Remote Repository

Navigate to GitHub and create a new, empty repository.

> [!IMPORTANT] Do Not Initialize the Remote Repository
> When creating the repository on GitHub, **do not** add a `README`, `.gitignore`, or license file. Your local repository already contains the project's history. Initializing the remote with files would create a divergent history, complicating your first push. It must be a completely empty shell.
- [ ] 9
```bash
ssh-keygen -t ed25519 -C "dusk1@myyahoo.com"
```
- [ ] 10
```bash
eval "$(ssh-agent -s)"
```
- [ ] 11
```bash
ssh-add ~/.ssh/id_ed25519
```
- [ ] 12
```bash
cat ~/.ssh/id_ed25519.pub
```
- [ ] 13
## Next, on the GitHub website:
    *   Navigate to **Settings > SSH and GPG keys**.
    *   Click **New SSH key**.
    *   Provide a descriptive **Title** (e.g., "Arch Linux Desktop").
    *   Paste the copied public key into the **Key** field.
    *   Click **Add SSH key**.

- [ ] 14
for the next command, you Might get an error saying `error: remote origin already exists.` and that's okay. continue on with the rest. 
```bash
git_dusky remote add origin git@github.com:dusklinux/dusky.git
```
- [ ] 15
```bash
git_dusky remote set-url origin git@github.com:dusklinux/dusky.git
```
- [ ] 16
```bash
ssh -T git@github.com
```

You may see a one-time warning about the host's authenticity; type `yes` and press Enter. A success message will include your GitHub username. The message "GitHub does not provide shell access" is normal and expected.
- [ ] 17
```bash
git_dusky branch -m main
git_dusky push -u origin main
```

---