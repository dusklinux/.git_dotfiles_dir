
# Waydroid Setup on Arch Linux

This guide provides a comprehensive walkthrough for installing and configuring Waydroid, an Android containerization solution, on an Arch Linux system. We will cover the initial setup, image placement, and basic management.

> [!NOTE] What is Waydroid?
> Waydroid runs a full Android system in a container on your Linux machine. It leverages your existing kernel and integrates tightly with the host system, offering near-native performance for Android apps.

---

### Prerequisites: Kernel Modules

Before you begin, it's crucial to verify that your Linux kernel has the necessary modules enabled for Waydroid to function.

1.  **Check for `binder` and `ashmem`:** (works without this as well)

Open a terminal and run the following command:

```bash
grep -E "binder|ashmem" /proc/filesystems
```

2.  **Verify the Output:**

You should see both `binder` and `ashmem` listed.

```
nodev	binder
nodev	ashmem
```

> [!note] (Optional, NOT NEEDED)
> If the command returns no output or is missing one of the modules, Waydroid will not work. On Arch Linux, the `linux`, `linux-lts` or `linux-zen` kernel includes these modules by default. You may need to install it and reboot your system. , it's possible with other kernals as well with the `binder_linux-dkms` package, refer to the arch wiki for more info
> ```bash
> sudo pacman -S --needed linux
> ```

---

### Step 1: Install the Waydroid Package

Use an AUR helper like `paru` or `yay` to install the main Waydroid package from the Arch User Repository (AUR).

```bash
paru -S waydroid
```

> [!IMPORTANT] Do Not Start Waydroid Yet!
> After the installation completes, do **not** start or initialize Waydroid immediately. You must first manually place the Android system images.

---

### Step 2: Download Android System Images

Waydroid requires two image files: `system.img` and `vendor.img`. You will download these from the official SourceForge repository.

1.  **Navigate to the Official Downloads Page:**
    [Waydroid Images on SourceForge](https://sourceforge.net/projects/waydroid/files/images/)

2.  **Choose Your Image Type:**
    You have two primary choices for the system image:
    *   **Vanilla:** A clean, open-source (AOSP) version of Android.
    *   **GApps:** Includes Google Play Services and the Play Store, which are required for many popular apps.

3.  **Download the Files:**
    *   Go into the `system` directory, select your preferred type (`gapps` or `vanilla`), and download the latest `system.img`.
    *   Go into the `vendor` directory and download the latest `vendor.img`.

> [!tip] Decompress the files with unzip
> ``` 
> unzip lineageos.....
> ```
	
> [!TIP] Which Image Should You Choose?
> For the most "phone-like" experience and access to the Google Play Store, the **GApps** image is recommended. If you prefer a de-Googled, open-source environment, choose **Vanilla**.

---

### Step 3: Prepare the System for Manual Images

Waydroid looks for manually-placed images in a specific directory. Create this directory structure now.

```bash
sudo mkdir -p /etc/waydroid-extra/images
```
*The `-p` flag creates parent directories as needed, preventing errors.*

---

### Step 4: Position the Android Images

Move the `system.img` and `vendor.img` files you downloaded into the directory you just created.

```bash
sudo mv /mnt/zram1/system.img /etc/waydroid-extra/images/
sudo mv /mnt/zram1/vendor.img /etc/waydroid-extra/images/
```

> [!NOTE]
> This command assumes your downloaded files are in the `/mnt/zram1/` folder. If you saved them elsewhere, adjust the source path accordingly.

---

### Step 5: Initialize Waydroid

Now you can initialize Waydroid. Because you placed the images manually, you must use the `-f` (force) flag to instruct Waydroid to use them instead of trying to download its own.

```bash
sudo waydroid init -f
```

This process will set up the container using your provided images.

---

### Step 6: Start and Manage the Waydroid Container

You can run Waydroid as a persistent background service or as a temporary session.

#### Method A: Systemd Service (Recommended)

This method starts the Waydroid container automatically on boot, making it always ready to use.

```bash
sudo systemctl enable --now waydroid-container
```

> [!tip] Restart your pc once and then open waydroid with rofi. 

#### Method B: Manual Session

This method starts a session that lasts until you stop it or reboot your machine. It's useful for on-demand use.

```bash
sudo waydroid session start
```

You can check the status of the container at any time with:

```bash
sudo waydroid status
```

Once the session is running, you should see the Waydroid application in your system's app launcher.

---

## FIXING BLACK SCREEN 

```bash
waydroid prop set persist.waydroid.multi_windows true
```
## Fixing Network issues. 
[[Waydroid Network & Firewall Configuration]]

## Fixing file sharing between host and container permission issues. 

[[File Permission Errors in Shared Folders]]
### Next Steps: ARM Compatibility and Rooting

Many Android applications are built for ARM processors. To run them on your x86 PC, you need a translation layer.

> [!INFO] Houdini ARM Translation
> **Houdini** is a proprietary translation layer that allows ARM-based applications to run on x86 hardware. Installing it is essential for broad app compatibility in Waydroid.

The easiest way to install Houdini is by using a script that also provides the option to root your Waydroid instance with Magisk. For detailed instructions, proceed to the next guide:

➡️ **See: [[Waydroid Rooting]]**

