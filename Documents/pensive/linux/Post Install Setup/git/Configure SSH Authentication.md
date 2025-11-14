### Step 8: Configure SSH Authentication

We will use SSH keys to securely connect to GitHub without needing to enter a password every time.

1.  **Generate an Ed25519 SSH Key Pair.** This is a modern and secure key type. When prompted, press Enter to save it to the default location and optionally create a strong passphrase.
```bash
ssh-keygen -t ed25519 -C "dusk1@myyahoo.com"
```

2.  **Start the `ssh-agent` in the background.** This process holds your private key in memory so you don't have to re-enter the passphrase for every connection.
```bash
eval "$(ssh-agent -s)"
```

3.  **Add your new SSH private key to the agent.** You will be prompted for the passphrase you created.
```bash
ssh-add ~/.ssh/id_ed25519
```

4.  **Add the Public Key to GitHub.**
- First, display the public key in your terminal and copy its entire output.

```bash
cat ~/.ssh/id_ed25519.pub
```
 
## Next, on the GitHub website:
    *   Navigate to **Settings > SSH and GPG keys**.
    *   Click **New SSH key**.
    *   Provide a descriptive **Title** (e.g., "Arch Linux Desktop").
    *   Paste the copied public key into the **Key** field.
    *   Click **Add SSH key**.
