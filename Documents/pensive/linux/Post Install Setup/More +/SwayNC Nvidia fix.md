Of course! Here is a beautifully formatted, step-by-step guide based on your note for fixing `SwayNC` on systems with NVIDIA GPUs. This version enhances clarity, adds explanatory callouts, and ensures it's easy to follow for any user.

***
> [!tip] For System-wide disabling of Nvidia Vulkan, See:-
>  [[System Wide Vulkan GPU Forcing]]



> [!note] The override is alreday backup to git. so this is not needed to be done if you've already restored the backup. 

# Forcing SwayNC to Use the Integrated GPU

On laptops with hybrid graphics (Intel + NVIDIA), some applications can unnecessarily engage the power-hungry NVIDIA GPU. This guide details how to create a specific `systemd` override to force `SwayNC` to use the more efficient Intel integrated GPU, saving battery life and reducing heat.

> [!NOTE] Why do this?
> The goal is to prevent `SwayNC`, a notification daemon, from activating the discrete NVIDIA GPU. By default, it may be picked up by the graphics driver, leading to unnecessary power consumption. This fix makes the application "invisible" to the NVIDIA driver by explicitly telling it to use the Intel Vulkan driver.

---

## The Step-by-Step Fix

This process involves creating a custom configuration file for the `swaync` systemd user service.

### Step 1: Create the Systemd Override Directory

First, you need to create the specific folder where `systemd` looks for custom configurations for the `swaync` user service.

> [!TIP] The `-p` Flag
> The `-p` flag in the `mkdir` command tells it to create any necessary parent directories. If `~/.config/systemd/user/` doesn't exist, this command creates it for you, preventing an error.

```bash
mkdir -p ~/.config/systemd/user/swaync.service.d/
```

### Step 2: Create the Override Configuration File

Next, create the configuration file that will hold our instructions. The name `gpu-fix.conf` is just an example; any name ending in `.conf` will work.

```bash
touch ~/.config/systemd/user/swaync.service.d/gpu-fix.conf
```

### Step 3: Add the GPU Configuration to the File

Open the newly created file with a text editor and add the following content. This configuration tells the `systemd` service to set a specific environment variable when launching `SwayNC`.

```bash
nvim ~/.config/systemd/user/swaync.service.d/gpu-fix.conf
```

 Then, add the following lines:
```ini
[Service]
ExecStart=
ExecStart=/usr/bin/env VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/intel_icd.x86_64.json /usr/bin/swaync
```

> [!IMPORTANT] How This Works
> *   `[Service]`: This heading tells `systemd` that the following directives apply to the service process itself.
> *   `Environment=`: This directive sets an environment variable for the command being executed.
> *   `"VK_ICD_FILENAMES=..."`: This is the crucial part. It tells the Vulkan graphics loader to **only** use the specified Intel driver manifest file (`intel_icd.x86_64.json`). This effectively hides the NVIDIA GPU from `SwayNC`.

### Step 4: Reload the Systemd Daemon

Your new configuration file is not active until you tell the `systemd` manager to scan for changes.

> [!INFO] `systemctl --user` vs. `sudo systemctl`
> *   `systemctl --user` manages services for your specific user account. They start when you log in and stop when you log out.
> *   `sudo systemctl` manages system-wide services that run for the entire system, usually from boot.
>
> Since `swaync` runs as a user service, we use the `--user` flag.

```bash
systemctl --user daemon-reload
```

### Step 5: Restart the SwayNC Service

To apply the new environment variable, you must restart the `SwayNC` service.

```bash
systemctl --user restart swaync.service
```

### Step 6: Verify the Fix was Successful

You can now confirm that `SwayNC` is no longer using the NVIDIA GPU.

```bash
nvidia-smi
```

> [!SUCCESS] Verification Complete
> After running the command, inspect the list of processes using the GPU. The `swaync` process should **no longer be listed**. This confirms that the fix is working correctly and `SwayNC` is now running on your integrated GPU.

---

## How to Revert the Changes

If you ever need to undo this fix, the process is simple.

1.  **Remove the override file** you created.
2.  **Reload the systemd daemon** to make it aware of the removal.
3.  **Restart the service** to have it launch with its default settings.

```bash
# Step 1: Remove the override file
rm ~/.config/systemd/user/swaync.service.d/gpu-fix.conf

# Step 2: Reload the systemd daemon
systemctl --user daemon-reload

# Step 3: Restart SwayNC
systemctl --user restart swaync.service
```

