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
#  systemd is free software; you can redistribute it and/or modify it under the
#  terms of the GNU Lesser General Public License as published by the Free
#  Software Foundation; either version 2.1 of the License, or (at your option)
#  any later version.
#
# Entries in this file show the compile time defaults. Local configuration
# should be created by either modifying this file (or a copy of it placed in
# /etc/ if the original file is shipped in /usr/), or by creating "drop-ins" in
# the /etc/systemd/logind.conf.d/ directory. The latter is generally
# recommended. Defaults can be restored by simply deleting the main
# configuration file and all drop-ins located in /etc/.
#
# Use 'systemd-analyze cat-config systemd/logind.conf' to display the full config.
#
# See logind.conf(5) for details.

[Login]
#NAutoVTs=6
#ReserveVT=6
#KillUserProcesses=no
#KillOnlyUsers=
#KillExcludeUsers=root
#InhibitDelayMaxSec=5
#UserStopDelaySec=10
#SleepOperation=suspend-then-hibernate suspend
HandlePowerKey=suspend
#HandlePowerKeyLongPress=ignore
#HandleRebootKey=reboot
#HandleRebootKeyLongPress=poweroff
#HandleSuspendKey=suspend
#HandleSuspendKeyLongPress=hibernate
#HandleHibernateKey=hibernate
#HandleHibernateKeyLongPress=ignore
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
#HandleLidSwitchDocked=ignore
#HandleSecureAttentionKey=secure-attention-key
#PowerKeyIgnoreInhibited=no
#SuspendKeyIgnoreInhibited=no
#HibernateKeyIgnoreInhibited=no
#LidSwitchIgnoreInhibited=yes
#RebootKeyIgnoreInhibited=no
#HoldoffTimeoutSec=30s
#IdleAction=ignore
#IdleActionSec=30min
#RuntimeDirectorySize=10%
#RuntimeDirectoryInodesMax=
#RemoveIPC=yes
#InhibitorsMax=8192
#SessionsMax=8192
#StopIdleSessionSec=infinity
#DesignatedMaintenanceTime=
#WallMessages=yes
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

