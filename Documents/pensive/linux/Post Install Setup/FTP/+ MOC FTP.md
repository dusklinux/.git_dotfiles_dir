
# Setting Up a `vsftpd` FTP Server on Arch Linux

This guide provides a comprehensive, step-by-step process for installing and configuring `vsftpd` (Very Secure FTP Daemon) on Arch Linux. We will cover package installation, firewall setup, user configuration, and service management to create a secure and functional FTP server.

---

> [!important]+ FTP server wont announce itself, enter your credentials/ ip manually and it should connect.

### Setup Process Overview


Here is a summary of the setup process. Each step links to a note with detailed instructions.

| Step | Action | Description |
| :--- | :--- | :--- |
| **1** | [[Install Required Packages]] | Installs the core `vsftpd` server and `firewalld` management tool required for the setup. |
| **2** | [[Configure the Firewall]] | Starts the firewall and opens the necessary ports to allow FTP traffic to reach the server securely. |
| **3** | [[Configure vsftpd]] | Defines the server's behavior, security rules, and user directory settings in the main configuration file. |
| **4** | [[Create the User Allow List]] | Creates an explicit list of users who are authorized to access the FTP server, enhancing security. |
| **5** | [[Start and Enable the vsftpd Service]] | Activates the FTP server and configures it to launch automatically every time the system boots. |
| **6** | [[zram permission]] | Gives zram requisite write permission |

> [!SUCCESS] Completion
> Once these steps are completed, you will have a fully functional and secure FTP server running on your Arch Linux system. For troubleshooting, refer to the log file mentioned in the final step.

