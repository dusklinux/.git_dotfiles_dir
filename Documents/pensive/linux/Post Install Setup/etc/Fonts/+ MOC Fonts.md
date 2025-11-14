
### **Step 1: Install a Custom Font**

While many fonts are available in the official Arch repositories, some, like `Atkinson Hyperlegible`, must be installed from the AUR. We will use `paru` for this example.

1.  **Install the Font Package**
    Use your preferred AUR helper to search for and install the font.

```bash
paru -S otf-atkinson-hyperlegible-next
```

---

### **Step 2: Identify the Font's Family Name**

Already done.
[[Font Family name search]]

2.  **Interpret the Output**

Already done. 
[[Identifying font family name]]

---

### **Step 3: Create a System-Wide Font Configuration**

Already done. 
[[Setting system wide fonts]]


 ## **Copy the Pre Configured Configuration file to the directory**
    Copy the local.conf file to the fonts directory in etc. 

```bash
sudo cp ~/fonts_and_old_stuff/setup/etc/fonts/local.conf /etc/fonts/
```



> [!NOTE] What does this file do?
> The `/etc/fonts/local.conf` file provides rules to `fontconfig`, the system's font management library. The `<alias>` rules above mean that whenever an application asks for a generic "sans-serif" font, the system will first try to provide "Atkinson Hyperlegible". If that's not available, it moves to the next font in the list.

---

### **Step 4: Refresh the Font Cache**

After installing a new font or changing the configuration, you must rebuild the system's font cache. This makes the system aware of the changes.

1.  **Run the Cache Command**
    Execute the following command with `sudo`. The `-f` flag forces a rebuild, and `-v` provides verbose output so you can see it working.

```bash
sudo fc-cache -fv
```

2.  **Restart Applications**
    Your changes are now active. For the new font settings to apply, you may need to restart running applications or your desktop session.

