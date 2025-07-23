### Step 4: Create the User Allow List

Because we set `userlist_deny=NO`, we must explicitly add allowed users to `/etc/vsftpd.userlist`.

This command adds a user to the list. Replace `your_username` with the actual username of the user you want to grant FTP access.

```bash
# Replace 'your_username' with the actual user's name
echo "your_username" | sudo tee /etc/vsftpd.userlist
```

> [!TIP]
> You can add multiple users by running the command for each one, or by editing the file directly with `sudo nvim /etc/vsftpd.userlist` and adding one username per line.
