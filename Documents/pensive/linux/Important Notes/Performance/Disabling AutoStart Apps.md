
# Managing Autostart Applications in Linux

This note provides a guide on how to identify and disable applications that are set to start automatically on system boot or user login. The focus is on applications located in the `/etc/xdg/autostart` directory.

## Understanding the Autostart Directory

The `/etc/xdg/autostart` directory contains `.desktop` files for applications that are configured to start automatically for all users on the system.

> [!CAUTION]
> Modifying files in `/etc/xdg/autostart` directly is not recommended. System updates can overwrite your changes. The best practice is to override these settings on a per-user basis.


## How to Disable Autostart Applications (The Right Way)

To disable an application from auto-starting for your user only, you can override the system-wide `.desktop` file by creating a modified copy in your local configuration directory.

### Step-by-Step Guide

1.  **Ensure the local autostart directory exists**:
    This directory is where your user-specific autostart configurations are stored.
    ```bash
    mkdir -p ~/.config/autostart
    ```

2.  **Copy the application's `.desktop` file**:
    Copy the file from the system directory to your local one. For this example, we'll disable the `blueman.desktop` application.
    ```bash
    cp /etc/xdg/autostart/blueman.desktop ~/.config/autostart/
    ```

3.  **Add [Desktop Entry]* and `Hidden=true` to the copied file**:
    This entry tells the desktop environment to hide this application from the startup process.
    ```bash
    nvim blueman.dekstop
    ```

	```bash
	[Desktop Entry]
	Hidden=true
	```


> [!SUCCESS]
> The application is now disabled from starting automatically on your next login. This method is non-destructive and only affects your user account.

### To Re-enable an Application

If you change your mind and want an application to autostart again, simply delete the `.desktop` file from your `~/.config/autostart` directory.

```bash
rm ~/.config/autostart/blueman.desktop
```

This will remove your user-specific override, and the system-wide autostart setting in `/etc/xdg/autostart` will take effect once more.


Here's a quick script you can run in the terminal to copy everyfile and automatically write Hidden=true to each of the copied file. 
```bash
# First, ensure the target directory exists
mkdir -p ~/.config/autostart

# Loop through each file in the system directory
for file in /etc/xdg/autostart/*.desktop; do
  # Get just the filename
  filename=$(basename "$file")
  
  # Create an overriding file in your local config that marks it as hidden
  echo "[Desktop Entry]" > ~/.config/autostart/"$filename"
  echo "Hidden=true" >> ~/.config/autostart/"$filename"
  
  echo "Disabled autostart for $filename"
done
```