
# 🔗 Relink to an Existing Dotfiles Repository

> [!help] READ THIS FIRST
> This guide outlines the process for pushing to an existing github repo to continue backing-up your local files after a fresh install of arch. this is after you've already restored with git_dusky checkout -f [[Restore Backup On a Fresh Install]]  
> you may have made some changes and that's perfectly fine, it'll add the changes as a commit, just like it would have previously on your old system when making changes. 

---

> [!NOTE] Follow these steps in order on your fresh installation.

### 1. 🧹 Clean Up (Optional)

First, ensure no old dotfiles repository exists. This command will remove the directory if it's present.

> This command permanently deletes the `dusky` directory from your home folder. 

```bash
rm -rf $HOME/dusky
```

### 2. 🆔 Set Global Git Identity

Before doing anything else, configure your Git identity on the new machine. This is a one-time setup.

*   [[Prerequisites Global Git Configuration]]

### 3. 🔐 Configure SSH Authentication

To securely communicate with GitHub without passwords, you must set up SSH keys.

*   [[Configure SSH Authentication]]

### 4. 📥 Clone the Bare Repository

Download your dotfiles' version history from GitHub into a hidden "bare" repository in your home directory.

```bash
git clone --bare git@github.com:dusklinux/dusky.git $HOME/dusky
```

this usually works 
`Are you sure you want to continue connecting (yes/no/[fingerprint])? yes`

### 5. ⚙️ Configure Repository Status

Tweak the local repository to hide untracked files. This keeps your status output clean and focused only on the files you explicitly manage.
*   [[Configure Repository Status]]

### 6. 📝 Track Files and Verify Status

Use your custom alias to add all tracked files from your list and then check the status to ensure everything is correct.

> [!IMPORTANT]+ Very Important to follow these steps sequentially. 

this will show a bunch of deleted files but that's okay. 
```bash
git_dusky status
```
this will reset the working area. 
```bash
git_dusky reset
```
now it should be clean. 
```bash
git_dusky status
```

```bash
git_dusky_add_list
```

Make your first commit but **DONT** push yet. 
```bash
git_dusky commit -m "fresh install first commit to the same old git repo"
```

### 7. 🤝 Link Local and Remote Repositories

Ensure your local repository is correctly pointing to the remote one on GitHub. (the first command might will say error: remote origin already exists., that's okay, continue on with the rest. )
*   [[Link Local and Remote Repositories]]

### 8. 🚀 Commit and Push

Finalize the setup by making an initial commit on the new machine and pushing it to your remote repository. This confirms the link is working.

```bash
git_dusky push -u origin main
```

> [!SUCCESS]
> Your new machine is now successfully linked to your dotfiles repository

