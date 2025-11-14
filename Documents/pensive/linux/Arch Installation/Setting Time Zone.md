
Configuring the correct time zone is a crucial step for your new system. It ensures the clock displays the correct local time and prevents potential issues with network services and package management that rely on accurate timekeeping.

> [!NOTE]
> These commands should be executed from within the `chroot` environment after you have installed the base system.

### 1. Set the Time Zone

You will set the system's time zone by creating a symbolic link from your chosen zone file to `/etc/localtime`.

> [!TIP] How to Find Your Time Zone
> If you're unsure of the exact path for your time zone, you can list the available regions and cities within the `/usr/share/zoneinfo` directory.
> ```bash
> # First, list the available regions (e.g., America, Europe, Asia)
> ls /usr/share/zoneinfo/
> 
> # Then, list the cities within your region
> ls /usr/share/zoneinfo/Asia/
> ```

Once you have identified your `Region/City`, use the following command to create the symbolic link. Replace `Asia/Kolkata` with your specific time zone.

```bash
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
```

### 2. Synchronize the Hardware Clock

After setting the system time zone, you need to synchronize this time with the hardware clock (RTC). This command sets the hardware clock from the system clock and creates the `/etc/adjtime` file, ensuring the time is persistent across reboots.

```bash
hwclock --systohc
```

> [!IMPORTANT]
> This command assumes your hardware clock is set to Coordinated Universal Time (UTC). This is the recommended standard for Linux systems to properly handle daylight saving time and avoid conflicts when dual-booting.

