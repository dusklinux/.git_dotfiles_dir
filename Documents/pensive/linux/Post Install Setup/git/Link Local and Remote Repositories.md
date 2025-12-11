### Step 9: Link Local and Remote Repositories

1.  **Get the SSH URL** from your new empty GitHub repository page or existing initialized repo. It should look like `git@github.com:username/repo.git`.

2.  **Add the remote** to your local repository's configuration.

```bash
git_dusky remote add origin git@github.com:dusklinux/dusky.git
```

Might get an error saying `error: remote origin already exists.` and that's okay. continue on with the rest. 

3.  **Set the URL.**

```bash
git_dusky remote set-url origin git@github.com:dusklinux/dusky.git
```

4.  **Verify the connection.**

```bash
ssh -T git@github.com
```

You may see a one-time warning about the host's authenticity; type `yes` and press Enter. A success message will include your GitHub username. The message "GitHub does not provide shell access" is normal and expected.
