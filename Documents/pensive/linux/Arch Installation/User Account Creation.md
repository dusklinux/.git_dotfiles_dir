
# 19. Create a User Account

For security and system integrity, you should not use the `root` account for daily activities. This step creates a standard user account for regular use.

### 1. Create the User and Assign Groups

Use the `useradd` command to create the new user. The `-m` flag creates a home directory for the user, and the `-G` flag adds the user to a list of supplementary groups, granting them necessary permissions for common hardware and tasks.

```bash
useradd -m -G wheel,input,audio,video,storage,optical,network,lp,power,games,rfkill your_username
```

> [!TIP]
> **Understanding the Groups**
> - **`wheel`**: This is the most important group. It allows the user to run administrative commands using `sudo` (which will be configured later).
> - **`audio`, `video`, `input`**: Provide access to sound, video, and input devices.
> - **`storage`, `optical`**: Allow access to storage devices like USB drives and CD/DVDs.
> - **`network`, `power`, `rfkill`**: Permit management of network connections, power state (reboot/shutdown), and wireless devices.

### 2. Set the User Password

Next, assign a password to the newly created account using the `passwd` command.

> [!CAUTION]
> **Specify the Username!**
> If you run `passwd` without specifying `your_username`, you will change the password for the **root** user, not your new user.

```bash
passwd your_username
```

You will be prompted to enter and confirm the new password. Once set, your user account is created and ready for the next steps.

