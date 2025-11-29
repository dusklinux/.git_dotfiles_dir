
# Fixing asusd D-Bus Misconfiguration on Arch Linux

This guide provides a step-by-step solution to a common D-Bus configuration issue with the `asusd` service on Arch Linux and Fedora-based systems.

---
> [!error]+ READ THIS
> Since you are on a rolling release (Arch), `asusd` updates might revert this file to the upstream default (bringing the bug back).
> 
> you could create a  **Pacman Hook** (`.hook` file) that runs this fix automatically every time `asusd` is updated. test this to work before implimenting [[asusd pacman hook]]


### The Problem: Incorrect Group Policy

The `asusd` service, which manages ASUS-specific hardware features, is often packaged with a D-Bus policy configured for Debian-based distributions. This policy grants permissions to the `sudo` user group.

However, Arch Linux uses the `wheel` group for administrative privileges by default, not `sudo`. Because the `sudo` group does not exist, the D-Bus policy fails, which can prevent `asusd` and related tools from functioning correctly.

> [!NOTE] Group Differences
> - **Debian/Ubuntu:** Use the `sudo` group for users who can run administrative commands.
> - **Arch Linux/Fedora:** Use the `wheel` group for the same purpose.

The misconfiguration is located in the `asusd.conf` file, which contains a policy block specifically for the `sudo` group.

### The Solution: Removing the Flawed Policy

To resolve this, we will edit the D-Bus configuration file and remove the incorrect policy block.

#### Step 1: Open the Configuration File

First, you need to open the `asusd.conf` file with a text editor.

> [!TIP] Administrative Privileges
> You will need `sudo` privileges to edit this system file. You can use any command-line text editor you are comfortable with, such as `nvim`, `vim`, or `nano`.

```bash
sudo nvim /usr/share/dbus-1/system.d/asusd.conf
```

#### Step 2: Delete the Incorrect Policy Block

Inside the file, locate and completely delete the `<policy>` block that references the `sudo` group. This block is usually found around line 9.

> [!CAUTION]
> Ensure you only remove the specified XML block. Deleting other parts of the file could break the service entirely.

**Remove this entire section:**
```xml
<policy group="sudo">
    <allow send_destination="xyz.ljones.Asusd"/>
    <allow receive_sender="xyz.ljones.Asusd"/>
</policy>
```

> [!note]- refereance file : full
> ```ini
> <!DOCTYPE busconfig PUBLIC
>           "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
>           "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
> <busconfig>
>     <policy group="adm">
>         <allow send_destination="xyz.ljones.Asusd"/>
>         <allow receive_sender="xyz.ljones.Asusd"/>
>     </policy>
>     <policy group="sudo">
>         <allow send_destination="xyz.ljones.Asusd"/>
>         <allow receive_sender="xyz.ljones.Asusd"/>
>     </policy>
>     <policy group="users">
>         <allow send_destination="xyz.ljones.Asusd"/>
>         <allow receive_sender="xyz.ljones.Asusd"/>
>     </policy>
>     <policy group="wheel">
>         <allow send_destination="xyz.ljones.Asusd"/>
>         <allow receive_sender="xyz.ljones.Asusd"/>
>     </policy>
>     <policy user="root">
>         <allow own="xyz.ljones.Asusd"/>
>         <allow send_destination="xyz.ljones.Asusd"/>
>         <allow receive_sender="xyz.ljones.Asusd"/>
>     </policy>
> </busconfig>
> ``` 

After removing it, save the file and exit the text editor.

#### Step 3: Apply the Changes

For the changes to take effect, you must restart the `asusd` service. This will force it to reload its D-Bus configuration.

```bash
sudo systemctl restart asusd.service
```



---

### Verification

Your `asusd` service should now be able to communicate correctly over D-Bus without permission errors. The fix is complete, and your ASUS-specific features should work as expected.
