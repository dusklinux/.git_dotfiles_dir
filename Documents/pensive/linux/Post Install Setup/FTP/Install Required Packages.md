### Step 1: Install Required Packages

First, ensure your system is up-to-date, then install `vsftpd` and `firewalld`, the firewall management tool we will use to secure the server.

```bash
sudo pacman -Syu vsftpd firewalld
```

> [!NOTE] What are we installing?
> - **`vsftpd`**: A lightweight, stable, and secure FTP server daemon.
> - **`firewalld`**: A dynamic firewall manager that makes it easy to define and apply security rules.
