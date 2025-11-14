### Step 2: Configure the Firewall

Before starting the FTP server, it's crucial to configure the firewall to allow the necessary traffic.

1.  **Enable and Start `firewalld`**
    This command starts the firewall immediately and ensures it launches automatically on boot.

    ```bash
    sudo systemctl enable --now firewalld
    ```

2.  **Define Firewall Rules**
    We need to open the standard FTP port (21) and the passive port range we will define later in the `vsftpd` configuration.

    ```bash
    # Allow the standard FTP service (port 21)
    sudo firewall-cmd --permanent --add-service=ftp

    # Allow the passive port range (40000-40100)
    sudo firewall-cmd --permanent --add-port=40000-40100/tcp
    ```

3.  **Apply the New Rules**
    Reload the firewall to make the new rules take effect.

    ```bash
    sudo firewall-cmd --reload
    ```
