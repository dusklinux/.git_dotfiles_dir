---
subject: SSH
context:
  - setup
  - arch install
type: guide
status: complete
---

## Server-Side Setup

On the machine you want to connect **to** (the server), follow these steps.

> [!info]
> These commands typically require root privileges. You may need to use `sudo` or be logged in as the `root` user.

1.  **Start the SSH Service**
- This command starts the SSH daemon (`sshd`), which listens for incoming connection requests.

```bash
systemctl start sshd.service
```

- To ensure the SSH service starts automatically every time the server boots, run:

```bash
systemctl enable sshd.service
```

2.  **Find the Server's IP Address**
- You need the server's local IP address to connect to it from another machine.

```bash
ip a
```

- Look for an `inet` address in the output, usually under an interface like `enpXsY` or `wlan0` It will look something like `192.168.29.xxx`.

3.  **Set a User Password**
- For password-based authentication, the user account you plan to log in with must have a password.

```bash
passwd
```

- If you are logged in as `root` and want to set the password for another user, run `passwd <username>`.

## Client-Side Connection

- On the machine you want to connect **from** (the client), open a terminal and use the `ssh` command.

- The general format is:

```bash
ssh <username>@<server_ip_address>
```

**Example:**
- To connect as the `root` user to a server at `192.168.29.123`:

```bash
ssh root@192.168.29.123
```

- The first time you connect, you will be asked to verify the authenticity of the host. Type `yes` and press Enter to continue.

## Troubleshooting

> [!warning] Host Key Verification Failed
> If you encounter an error like `REMOTE HOST IDENTIFICATION HAS CHANGED!` `or someone is snooping on the connection` , it means the server's SSH key stored on your client does not match the one the server is now presenting. This often happens after reinstalling the server's operating system or if the IP address was previously used by another device.

**Solution:**
- To resolve this, you must remove the old, incorrect key from your client machine.

- Run the following command on the **client**, replacing `<server_ip_address>` with your server's actual IP:

```bash
ssh-keygen -R <server_ip_address>
```

**Example:**

```bash
ssh-keygen -R 192.168.29.123
```

- After removing the old key, try connecting via SSH again. You will be prompted to accept the new key fingerprint.
