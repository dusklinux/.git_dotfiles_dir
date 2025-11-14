### Step 5: Start and Enable the `vsftpd` Service

Finally, start the FTP server and enable it to launch automatically at system startup.

```bash
sudo systemctl enable --now vsftpd.service
```

Your `vsftpd` server is now configured and running. You can test the connection from another computer using an FTP client like FileZilla or the command-line `ftp` tool. For troubleshooting, check the log file at `/var/log/vsftpd.log`.
