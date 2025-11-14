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
2.  **Create the Link:** Use the `ln -nfs` command to create the link. The structure is `ln -nfs /path/to/real/folder /path/to/link`.

> [!TIP]
> Before creating the link, make sure the original `~/.mozilla` folder in your home directory has been moved or deleted. You cannot create a link if a file or folder with the same name already exists at the destination.

Here is the command from your notes, generalized for any user and location:

```bash
# Syntax: sudo ln -nfs <TARGET_DIRECTORY> <LINK_LOCATION>
sudo ln -nfs /path/to/your/external/drive/.mozilla ~/.mozilla
```

**Example from your notes:**
This command links the `.mozilla` folder from an external drive mounted at `/mnt/browser/.mozilla` to the location where Firefox expects to find it in the user's home directory.

```bash
sudo ln -nfs /mnt/browser/.mozilla ~/.mozilla
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


hiding sidebar: 
```bash
about:config
```
enable 
```bash
toolkit.legacyUserProfileCustomizations.stylesheets
```

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


>[!important]- here's the full userChrome.css file for themeing. 
> ```
> @import url("../../../../.config/theming/current/firefox.css");
> 
> :root {
>   /* "toolbar": "rgb(12, 76, 125)", */
>   --toolbar-bgcolor: var(--theme-bg-toolbar) !important;
>   /* "toolbar_text": "rgb(255, 255, 255)", */
>   --toolbar-color: var(--theme-text) !important;
>   /* "frame": "rgb(7, 43, 71)", */
>   --lwt-accent-color: var(--theme-bg-frame) !important;
>   --lwt-accent-color-inactive: var(--theme-bg-frame) !important;
>   --toolbox-bgcolor: var(--theme-bg-frame) !important;
>   --toolbox-bgcolor-inactive: var(--theme-bg-frame) !important;
>   /* "tab_background_text": "rgb(255, 255, 255)", */
>   --lwt-text-color: var(--theme-text) !important;
>   /* "toolbar_field": "rgb(3, 18, 30)", (search bar) */
>   --toolbar-field-background-color: var(--theme-bg-frame) !important; /* CONSOLIDATED */
>   --toolbar-field-focus-background-color: var(--theme-bg-frame) !important; /* CONSOLIDATED */
>   /* "toolbar_field_text": "rgb(255, 255, 255)", (search text)*/
>   --toolbar-field-color: var(--theme-text) !important;
>   --toolbar-field-focus-color: var(--theme-text) !important;
>   /* "tab_line": "rgb(3, 18, 30)", */
>   --lwt-tab-line-color: var(--theme-bg-frame) !important; /* CONSOLIDATED */
>   /* "popup": "rgba(29, 29, 30, 0.99)", */
>   --arrowpanel-background: var(--popup-bg) !important;
>   /* "popup_text": "rgb(255, 255, 255)", */
>   --arrowpanel-color: var(--theme-text) !important;
>   /* "tab_loading": "rgb(3, 18, 30)" */
>   --tab-loading-fill: var(--theme-bg-frame) !important; /* CONSOLIDATED */
>   /* "button_background_active": "rgb(255, 86, 3)", */
>   --toolbarbutton-active-background: var(--theme-accent) !important;
>   /* "icons": "rgb(255, 255, 255)", */
>   --toolbarbutton-icon-fill: var(--theme-text) !important;
>   /* "ntp_text": "rgb(255, 255, 255)", */
>   --newtab-text-primary-color: var(--theme-text) !important;
>   /* "popup_highlight_text": "rgb(255, 255, 255)", */
>   --urlbarView-highlight-color: var(--theme-text) !important;
>   /* "sidebar_highlight_text": "rgb(255, 255, 255)", */
>   /* --urlbarView-highlight-color: rgb(255, 255, 255) !important; */ /* Original was commented out/duplicate */
>   /* "sidebar_text": "rgb(255, 255, 255)", */
>   --sidebar-text-color: var(--theme-text) !important;
>   /* Others*/
>   --tab-selected-textcolor: var(--theme-text) !important;
>   --tab-selected-bgcolor: var(--theme-bg-toolbar) !important;
>   --toolbar-field-border-color: var(--field-border) !important;
>   --button-background-color-hover: var(--theme-accent-hover) !important;
>   --button-background-color-active: var(--theme-accent-hover) !important;
>   --urlbarView-hover-background: var(--theme-accent-hover) !important;
>   --panel-separator-zap-gradient: linear-gradient(
>       90deg,
>       #9059ff 0%,
>       #ff4aa2 52.08%,
>       #ffbd4f 100%
>     ) !important;
> }
> /* Sidebar buttons hover */
> .button-background {
>   button:hover > & {
>     background-color: var(--theme-accent-hover) !important;
>   }
> }
> /* Buttons colors */
> #urlbar {
>   --urlbar-box-bgcolor: var(--theme-accent) !important;
>   --urlbar-box-focus-bgcolor: var(--theme-accent) !important;
>   --urlbar-box-hover-bgcolor: var(--theme-accent-hover) !important;
> }
> /* Round elements */
> :root {
>   --urlbar-icon-border-radius: 20px !important;
> }
> #urlbar-background,
> #urlbar {
>   border-radius: 20px !important;
> }
> .menupopup-arrowscrollbox {
>   border-radius: 16px !important;
> }
> /* Remove top space in the browser */
> .titlebar-spacer {
>   display: none !important;
> }
> /* Hide bookmark folder icon */
> .bookmark-item[container="true"] .toolbarbutton-icon {
>   display: none !important;
> }
> /* Line beneath bookmark folder icon */
> .bookmark-item[container="true"] {
>   border-bottom: 2px solid var(--theme-accent) !important;
>   border-bottom-right-radius: 0% !important;
>   clip-path: polygon(0 0, 100% 0, 100% 100%, 60px 90%, 0 100%);
> }
> /* Clean context menu /
> / Remove Email Image/Video */
> #context-sendimage,
> #context-sendvideo {
>   display: none !important;
> }
> /* Remove Inspect Accessibility Properties */
> #context-inspect-a11y {
>   display: none !important;
> }
> /* Remove Print Selection */
> #context-print-selection {
>   display: none !important;
> }
> /* Remove Set Image as Desktop Background */
> #context-setDesktopBackground,
> #context-sep-setbackground {
>   display: none !important;
> }
> /* Remove Save Link to Pocket */
> #context-savelinktopocket,
> #context-pocket {
>   display: none !imporant;
> }
> /* Hide the main sidebar container */
> #sidebar-main {
>   display: none !important;
> }
> 
> /* Also hide the sidebar header for a clean look */
> #sidebar-panel-header {
>   display: none !important;
> }
> 
> ```


# HIDING ANY ELEMENT WITHIN FIREFOX

> [!SUCESS] [[Firefox Custom Element Hide]]