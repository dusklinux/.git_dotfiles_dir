
The hostname is a unique name that identifies your computer on a network. This step assigns that name to your new Arch Linux system.

### 1. Set the Hostname

Execute the following command to write your desired hostname to the `/etc/hostname` configuration file. Replace `your-hostname` with the name you want to assign to your computer.

```bash
echo "your-hostname" > /etc/hostname
```

> [!TIP] Choosing a Good Hostname
> A good hostname is simple, memorable, and contains only alphanumeric characters and hyphens. For example: `arch-desktop`, `thinkpad-t14`, or `mediaserver`.

> [!NOTE] Hostname vs. Username
> The hostname identifies your *computer*, while a username identifies a *user account* on that computer. While they can be the same, it's standard practice to keep them distinct for clarity.

### 2. (Optional) Verify the Hostname

You can confirm that the hostname was set correctly by displaying the contents of the file you just created.

```bash
cat /etc/hostname
```

The output should be the exact hostname you entered in the previous command.

### Next Steps

After setting the hostname, the next logical step is often to configure the `/etc/hosts` file to ensure proper local name resolution. You can find more information on this and other important files in [[Key Configuration Files in Arch Linux]].
