### Step 3: Configure `vsftpd`

The core of the setup lies in the `/etc/vsftpd.conf` file. We will replace the default configuration with a secure and explicit setup.

1.  **Open the Configuration File**
    Use a text editor like `nvim` or `nano` to edit the file with root privileges.

    ```bash
    sudo nvim /etc/vsftpd.conf
    ```

2.  **Apply the Configuration**
    Delete all existing text in the file and paste the following configuration. Each directive is commented to explain its purpose.

    > [!IMPORTANT] Customize Your Root Directory
    > The `local_root` directive specifies the directory users will be confined to. **Change `/mnt/zram1`** to the actual path you want to serve via FTP (e.g., `/srv/ftp`, `/home/your_username/ftp_share`).


> [!note]+ 
>```ini
># --- Access Control ---
># Allow anonymous FTP? (NO for security)
>anonymous_enable=NO
># Allow local users to log in? (YES)
>local_enable=YES
># Enable any form of write commands? (YES/NO based on user input)
>write_enable=YES
>
># --- Chroot and Directory Settings ---
># Restrict local users to their chroot jail after login.
>chroot_local_user=YES
># If chroot_local_user is YES, and the chroot directory (local_root) is writable by the user,
># this option must be YES. This is a common requirement.
>allow_writeable_chroot=YES
># Specify the directory to which local users will be chrooted.
># This becomes their FTP root directory.
>local_root=/mnt/zram1
>
># --- User Authentication and Listing ---
># Enable the use of a userlist file.
>userlist_enable=YES
># Path to the userlist file.
>userlist_file=/etc/vsftpd.userlist
># When userlist_deny=NO, the userlist_file acts as an allow list.
># Only users explicitly listed in userlist_file can log in.
>userlist_deny=NO
>
># --- Logging ---
># Enable transfer logging.
>xferlog_enable=YES
># Use standard log file format.
>xferlog_std_format=YES
># Path to the vsftpd log file.
>xferlog_file=/var/log/vsftpd.log
># Log all FTP protocol commands and responses (can be verbose, useful for debugging).
>log_ftp_protocol=YES
>
># --- Connection Handling ---
># Standalone mode. listen=NO is needed if listen_ipv6=YES for dual-stack.
>listen=NO
># Listen on IPv6 (implies IPv4 as well on modern systems).
>listen_ipv6=YES
># PAM service name for authentication.
>pam_service_name=vsftpd
>
># --- Passive Mode (Essential for NAT/Firewalls) ---
># Enable passive mode.
>pasv_enable=YES
># Minimum port for passive connections.
>pasv_min_port=40000
># Maximum port for passive connections.
>pasv_max_port=40100
># You can optionally set pasv_address=YOUR_EXTERNAL_IP if behind NAT,
># but for a local laptop, this is usually not needed.
>
># --- Banners and Messages ---
># Display a login banner.
>ftpd_banner=Welcome to this Arch Linux FTP service.
>
># --- Performance and Security Tweaks ---
># Use sendfile() system call for transferring files (efficient).
>use_sendfile=YES
># Ensure PORT transfer connections originate from port 20 (ftp-data) on the server.
>connect_from_port_20=YES
># Optional: Hide user and group information in directory listings (shows 'ftp ftp').
># hide_ids=YES
>
># --- Filesystem Encoding ---
># The utf8_filesystem option was removed as it caused errors on some systems.
># Modern systems generally handle UTF-8 well by default.
># utf8_filesystem=YES 
>
># --- End of vsftpd.conf ---
>```

    > [!WARNING] Security Note on `allow_writeable_chroot`
    > Setting `allow_writeable_chroot=YES` is convenient but carries security risks. The recommended practice is to have the `local_root` directory be owned by `root` and not be writable by the FTP user. You can then create subdirectories inside it that are owned by the FTP user.
