# Configuring the Power Key Behavior in Arch Linux

This guide details how to change the default action of your system's physical power button. By default, pressing the power button often triggers a system shutdown. We will modify a `systemd` configuration file to change this behavior to **suspend**, which is often more convenient for daily use.

---

## Step 1: Edit the `logind.conf` File

The power key actions are managed by `systemd-logind`. The first step is to edit its primary configuration file.

> [!TIP] Administrative Privileges
> You will need administrative (`sudo`) privileges to edit this system file. You can use any command-line text editor you prefer, such as `nvim`, `vim`, or `nano`.

Open the configuration file using your preferred editor:
```bash
sudo nvim /etc/systemd/logind.conf
```

## Step 2: Modify the `HandlePowerKey` Setting

Inside the file, you will find many commented-out options that show the default settings. We need to locate the line for `HandlePowerKey`.

1.  Find the line `#HandlePowerKey=poweroff`.
2.  **Uncomment** the line by removing the `#` at the beginning.
3.  **Change** the value from `poweroff` to `suspend`.

Your change should look like this:

```ini
#  This file is part of systemd.
#
#  systemd is free software; you can redistribute it and/or modify it
#  under the terms of the GNU Lesser General Public License as published by
#  the Free Software Foundation; either version 2.1 of the License, or
#  (at your option) any later version.
#
...
#HandleLidSwitch=suspend
#HandleLidSwitchExternalPower=suspend
#HandleLidSwitchDocked=ignore
HandlePowerKey=suspend
#HandleSuspendKey=suspend
#HandleHibernateKey=hibernate
...
```

> [!NOTE] Other Power Options
> As you can see in the file, you can also configure the behavior for other events, such as closing a laptop lid (`HandleLidSwitch`) or pressing the suspend key (`HandleSuspendKey`).

## Step 3: Apply the Changes

For the new setting to take effect, you must restart the `systemd-logind` service.

> [!NOTE]
> when you later reboot, changes will be applied automatically. 




---

## Verification

Your setup is complete. You can now test the new behavior by pressing your computer's power button. The system should enter suspend mode instead of shutting down.

To revert this change at any time, simply edit the `/etc/systemd/logind.conf` file again, set `HandlePowerKey=poweroff` (or comment the line out to restore the default), and restart the service.

