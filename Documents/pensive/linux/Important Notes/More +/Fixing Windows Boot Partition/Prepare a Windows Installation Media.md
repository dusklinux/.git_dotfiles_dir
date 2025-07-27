
# Preparing a Bootable USB with Ventoy

Ventoy is a powerful open-source tool that allows you to create a bootable USB drive simply by copying ISO files onto it. This guide will walk you through setting up a Ventoy USB on a Linux system, which you can then use to boot and install Windows or any other operating system.

---

### Step 1: Download Ventoy for Linux

First, you need to download the latest version of Ventoy. You can find the release files on their official website or GitHub page.

*   **Official Download Page:**
    ```url
    https://www.ventoy.net/en/download.html
    ```
*   **GitHub Releases:**
    ```url
    https://github.com/ventoy/Ventoy/releases
    ```

Download the `...-linux.tar.gz` file.

### Step 2: Extract and Prepare Ventoy

Once the download is complete, you'll need to extract the archive and navigate into the directory using the terminal.

1.  **Navigate to Downloads**
    Open your terminal and change the directory to where you downloaded the file. For most users, this will be the `Downloads` folder.
    ```bash
    cd ~/Downloads
    ```

2.  **Extract the Archive**
    The Ventoy files are compressed in a `.tar.gz` archive. Use the `tar` command to extract them.

    > [!TIP] Pro Tip
    > The version number in the filename will change with new releases. You can type `tar -xzvf ventoy-` and press the `Tab` key to autocomplete the rest of the filename.

    ```bash
    # Replace the version number with the one you downloaded
    tar -xzvf ventoy-1.1.05-linux.tar.gz
    ```

3.  **Enter the Ventoy Directory**
    After extraction, a new directory will be created. Use the `cd` command to enter it.
    ```bash
    # Again, use Tab to autocomplete the directory name
    cd ventoy-1.1.05
    ```

### Step 3: Launch the Ventoy Web Interface

Ventoy provides a user-friendly web-based interface to install it onto your USB drive. This avoids complex command-line operations.

1.  **Execute the Web UI Script**
    Run the `VentoyWeb.sh` script with `sudo` to grant it the necessary permissions to write to your USB drive.
    ```bash
    sudo ./VentoyWeb.sh
    ```

2.  **Access the Web Interface**
    The terminal will output a message indicating that the server has started and provide a URL.
    ```text
    ===============================================================
        Ventoy Web UI is running at http://127.0.0.1:24680
    ===============================================================
    Please open your browser and visit the URL above.
    ```
    Copy the URL (`http://127.0.0.1:24680`) and paste it into your web browser's address bar.

> [!NOTE] Secure Boot Support
> By default, Ventoy enables support for Secure Boot. The 🔒 (lock) symbol next to the version number in the web interface indicates that this feature is active.

### Step 4: Install Ventoy and Add ISOs

Now you can install Ventoy onto your USB drive and add your operating system images.

1.  **Install Ventoy to USB**
    In the Ventoy web interface, select your target USB drive from the dropdown menu.

    > [!WARNING] Data Loss
    > The installation process will format the selected USB drive, erasing **all data** on it. Double-check that you have selected the correct drive and backed up any important files.

    Click the **Install** button and confirm the action.

2.  **Copy ISO Files**
    Once Ventoy is installed, your USB drive will be partitioned. A large partition labeled `Ventoy` will be visible in your file manager. To make a bootable OS, simply **drag and drop** the ISO file (e.g., `Windows11.iso`) into this `Ventoy` partition. You can add multiple ISO files, and Ventoy will present you with a menu to choose from when you boot from it.

> [!TIP] Check OS Compatibility
> While Ventoy supports a vast number of ISO files, it's always a good idea to check the official [Tested ISO List](https://www.ventoy.net/en/isolist.html) if you encounter issues with a specific operating system.

### Step 5: Booting and Troubleshooting

With your ISOs copied, you can now boot from the USB drive.

1.  **Boot from the USB:** Restart your computer and enter the BIOS/UEFI settings (usually by pressing `F2`, `F12`, or `Del` during startup). Select the Ventoy USB drive as the primary boot device.
2.  **Select an OS:** The Ventoy boot menu will appear, listing all the ISO files you copied. Select the one you want to boot and press Enter.

#### Troubleshooting Common Boot Issues

If a specific ISO fails to boot correctly, Ventoy offers special modes you can activate from the boot menu.

> [!NOTE] Boot Mode Hotkeys
> You can press a hotkey **before** hitting Enter on a selected ISO to change its boot mode for that session.
>
> - **WIMBOOT Mode (`Ctrl + w`):** Use this mode if you run into problems while booting a **Windows ISO**. It can help resolve compatibility issues with certain hardware.
> - **GRUB2 Mode (`Ctrl + r`):** Use this mode if a **Linux distro** fails to boot. This is effective for distributions that include a `grub2` configuration file.

