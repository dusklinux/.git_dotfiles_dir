# 🦊 Managing Firefox Data on Arch Linux

This guide provides essential commands and procedures for managing your Firefox user data on Arch Linux. It covers backing up your profile, performing a complete data wipe, and using symbolic links for portable configurations.

---

## 1. Backing Up and Restoring Your Firefox Profile

Your Firefox profile contains all your personal data, including saved logins, bookmarks, history, extensions, and settings. Backing up this profile is crucial for migrating to a new system or recovering your setup.

### [[Firefox Profile Directory]]

> [!NOTE] The Golden Folder
> The `~/.mozilla` directory is all you need. To back it up, simply copy this entire folder to a safe location (like an external drive or cloud storage). To restore, close Firefox, delete the existing `~/.mozilla` folder on the new system, and replace it with your backup. Note that copy pasting the folder logs you out of some accounts, it's a security feature that some websites implement, ie when they notice the data was copied, it logs you out.   

---

## 2. Completely Wiping Firefox Data

If you need to reset Firefox to a factory-fresh state, you must remove its profile and cache files.

> [!WARNING] Destructive Action
> The following commands will permanently delete all your Firefox data, including passwords, bookmarks, and history. This action cannot be undone. Proceed with caution.

To completely wipe all traces of Firefox user data, execute the following commands in your terminal:

```bash
# Removes the primary Firefox profile data
rm -rf ~/.mozilla/firefox/

# Removes the parent .mozilla directory, catching all related data
rm -rf ~/.mozilla

# Clears the application cache for Firefox
rm -rf ~/.cache/mozilla
```

You can run these commands one by one or combine them for a quicker process:
```bash
rm -rf ~/.mozilla/firefox/ ~/.mozilla ~/.cache/mozilla
```

---

## 3. Using a Symbolic Link for a Portable Profile

A symbolic link (or symlink) can redirect Firefox to use a profile stored in a different location, such as on a separate partition or an external USB drive. This is an excellent way to maintain a portable setup or save space on your primary drive.

For a detailed explanation of how symbolic links work, see the [[General Tips]] note.

### How to Create the Symbolic Link

1.  **Move Your Profile:** First, ensure Firefox is closed. Then, move your existing `~/.mozilla` folder to the desired new location (e.g., an external drive).
2.  **Create the Link:** Use the `ln -s` command to create the link. The structure is `ln -s /path/to/real/folder /path/to/link`.

> [!TIP]
> Before creating the link, make sure the original `~/.mozilla` folder in your home directory has been moved or deleted. You cannot create a link if a file or folder with the same name already exists at the destination.

Here is the command from your notes, generalized for any user and location:

```bash
# Syntax: sudo ln -s <TARGET_DIRECTORY> <LINK_LOCATION>
sudo ln -s /path/to/your/external/drive/.mozilla ~/.mozilla
```

**Example from your notes:**
This command links the `.mozilla` folder from an external drive mounted at `/mnt/browser/.mozilla` to the location where Firefox expects to find it in the user's home directory.

```bash
sudo ln -s /mnt/browser/.mozilla ~/.mozilla
```

---

# Firefox: Enabling Hardware Acceleration and Enhanced Scrolling

This guide details the necessary `about:config` tweaks and standard settings adjustments to enable hardware-accelerated video decoding and improve the scrolling experience in Firefox. These changes can lead to significantly lower CPU usage during video playback and a smoother, more pleasant browsing experience.

---

## 1. Hardware Video Acceleration (VA-API)

Enabling hardware acceleration offloads video decoding from the CPU to the GPU, which is crucial for smooth playback of high-resolution content and improved battery life on laptops. This is achieved by enabling Firefox's support for the Video Acceleration API (VA-API), the same technology used by native video players like [[MPV]].

### Accessing `about:config`

1.  Type `about:config` into the Firefox address bar and press Enter.
2.  A warning page may appear. Click "Accept the Risk and Continue" to proceed.

### Configuration Settings

Use the search bar at the top of the `about:config` page to find and modify the following preferences. You can double-click a preference to toggle its value between `true` and `false`.

| Preference Name | Recommended Value | Description |
| :--- | :--- | :--- |
| `gfx.webrender.all` | `true` | Enables the high-performance WebRender rendering engine for all system configurations, which is beneficial for overall browser performance and works well with hardware acceleration. |
| `media.hardware-video-decoding.force-enabled` | `true` | **(Last Resort)** Forces hardware decoding to be active even if Firefox's internal checks fail. Use this only if the other settings don't work. |

> [!WARNING] Forcing Can Cause Instability
> The `media.hardware-video-decoding.force-enabled` option overrides Firefox's compatibility checks. While it can solve issues on some systems, it may lead to graphical glitches, crashes, or black video screens on others. Enable it only as a final troubleshooting step.

---

## 2. Enhanced Scrolling Experience

These settings, available in the standard Firefox options menu, can make navigating web pages feel much more fluid and intuitive.

### How to Enable Scrolling Features

1.  Navigate to Firefox **Settings**.
2.  Select the **General** tab on the left.
3.  Scroll down to the **Browsing** section.

### Recommended Settings

Ensure the following options are checked:

-   `[x]` **Use autoscrolling**
    -   **Functionality**: Allows you to scroll through a page by clicking the middle mouse button (scroll wheel) and moving the mouse up or down. This enables rapid, continuous scrolling without repeatedly using the scroll wheel.

-   `[x]` **Use smooth scrolling**
    -   **Functionality**: Instead of jumping line-by-line, this setting animates the scroll motion, making page navigation feel smoother and less jarring.


hiding sidebar: about:config
enable 
toolkit.legacyUserProfileCustomizations.stylesheets

about:profiles and open root directory path. and paste the premade chrome directory in which the userChrome.css file was previously created.

here is the userChrome.css files's contents if you've lost it. 
```css
#sidebar-main {
  display: none !important;
}
#sidebar-panel-header {
  display: none !important;
}
```


# HIDING ANY ELEMENT WITHIN FIREFOX

> [!SUCESS] [[Firefox Custom Element Hide]]