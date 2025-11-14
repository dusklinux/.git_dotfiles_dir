Ensuring the system clock is accurate is a critical step. An incorrect clock can cause issues with network connections, package signature verification, and other time-sensitive operations.

### 1. Set the Timezone

First, you need to set the correct timezone for your location.

> [!TIP] Find Your Timezone
> If you are unsure of your timezone's exact name, you can list all available timezones with the following command. You can use `grep` to filter the list for your city or region.
> ```bash
> timedatectl list-timezones | grep Kolkata
> ```

Once you know your timezone, set it using the `timedatectl set-timezone` command. Replace `Asia/Kolkata` with your specific `Region/City`.

```bash
timedatectl set-timezone Asia/Kolkata
```

### 2. Enable Network Time Protocol (NTP)

Next, enable NTP to allow the system to automatically synchronize its clock with a remote server over the network. This ensures the time remains accurate.

```bash
timedatectl set-ntp true
```

> [!NOTE] Importance of NTP
> Keeping NTP enabled is highly recommended. It automatically corrects for clock drift, ensuring your system time is always precise.

### 3. Verify the Configuration

Finally, verify that the system clock is synchronized and the correct timezone has been applied.

```bash
timedatectl status
```

Running this command will display the current local time, universal time (UTC), your configured timezone, and confirm that the NTP service is active.
