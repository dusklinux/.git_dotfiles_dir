
This guide details how to configure system-wide account lockout policies after a specified number of failed login attempts. This security measure is controlled by the `faillock.conf` file, which configures the `pam_faillock` module.

### Step 1: Open the Configuration File

To begin, you need to edit the `faillock.conf` file with root privileges. You can use any command-line text editor like `nvim`, `vim`, or `nano`.

```bash
sudo nvim /etc/security/faillock.conf
```

### Step 2: Set the Lockout Parameters

Inside the file, you can either find and modify the existing (and likely commented-out) default settings or simply add the following configuration block anywhere in the file. Adding it as a new block is often cleaner and easier to manage.

> [!TIP]
> For clarity, it's good practice to add a comment above your custom settings, such as `# Custom lockout policy`.

#### Configuration

Copy and paste the following lines into the `/etc/security/faillock.conf` file.

```ini
# --- Custom Account Lockout Policy ---

# Number of failed attempts before the account is locked.
deny = 6

# Time in seconds for which a non-root account will be locked.
unlock_time = 90

# Time in seconds for which the root account will be locked.
# It is recommended to set this to a higher value for enhanced security.
root_unlock_time = 200
```

### Parameter Breakdown

Here is a detailed explanation of each configuration directive:

| Parameter | Description | Example Value |
|---|---|---|
| `deny` | The number of consecutive failed authentication attempts after which the user account is locked. | `6` |
| `unlock_time` | The duration in seconds for which the account remains locked. After this time, the account is automatically unlocked. | `30` (30 seconds) |
| `root_unlock_time` | A separate, often stricter, unlock time specifically for the `root` account. | `90` (90 seconds) |

> [!IMPORTANT]
> After saving your changes, the new policy will be active for subsequent login attempts. No service restart is typically required as the PAM stack reads this configuration during the authentication process.

