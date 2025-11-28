
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

> [!NOTE]- unwravel to view file
> ```ini
> # Configuration for locking the user after multiple failed
> # authentication attempts.
> #
> # The directory where the user files with the failure records are kept.
> # The default is /var/run/faillock.
> # dir = /var/run/faillock
> #
> # Will log the user name into the system log if the user is not found.
> # Enabled if option is present.
> # audit
> #
> # Don't print informative messages.
> # Enabled if option is present.
> # silent
> #
> # Don't log informative messages via syslog.
> # Enabled if option is present.
> # no_log_info
> #
> # Only track failed user authentications attempts for local users
> # in /etc/passwd and ignore centralized (AD, IdM, LDAP, etc.) users.
> # The `faillock` command will also no longer track user failed
> # authentication attempts. Enabling this option will prevent a
> # double-lockout scenario where a user is locked out locally and
> # in the centralized mechanism.
> # Enabled if option is present.
> # local_users_only
> #
> # Deny access if the number of consecutive authentication failures
> # for this user during the recent interval exceeds n tries.
> # The default is 3.
> deny = 6
> #
> # The length of the interval during which the consecutive
> # authentication failures must happen for the user account
> # lock out is <replaceable>n</replaceable> seconds.
> # The default is 900 (15 minutes).
> # fail_interval = 900
> #
> # The access will be re-enabled after n seconds after the lock out.
> # The value 0 has the same meaning as value `never` - the access
> # will not be re-enabled without resetting the faillock
> # entries by the `faillock` command.
> # The default is 600 (10 minutes).
> unlock_time = 90
> #
> # Root account can become locked as well as regular accounts.
> # Enabled if option is present.
> # even_deny_root
> #
> # This option implies the `even_deny_root` option.
> # Allow access after n seconds to root account after the
> # account is locked. In case the option is not specified
> # the value is the same as of the `unlock_time` option.
> root_unlock_time = 300
> #
> # If a group name is specified with this option, members
> # of the group will be handled by this module the same as
> # the root account (the options `even_deny_root>` and
> # `root_unlock_time` will apply to them.
> # By default, the option is not set.
> # admin_group = <admin_group_name>
> ```

### Parameter Breakdown

Here is a detailed explanation of each configuration directive:

| Parameter | Description | Example Value |
|---|---|---|
| `deny` | The number of consecutive failed authentication attempts after which the user account is locked. | `6` |
| `unlock_time` | The duration in seconds for which the account remains locked. After this time, the account is automatically unlocked. | `30` (30 seconds) |
| `root_unlock_time` | A separate, often stricter, unlock time specifically for the `root` account. | `90` (90 seconds) |

> [!IMPORTANT]
> After saving your changes, the new policy will be active for subsequent login attempts. No service restart is typically required as the PAM stack reads this configuration during the authentication process.

