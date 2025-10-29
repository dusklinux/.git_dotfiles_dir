# Preliminary Identification: Locating Your Windows Installation

Before we can begin repairs, we must first orient ourselves within the Windows Recovery Environment. Our primary objective is to pinpoint the exact physical disk where Windows is installed and determine the drive letter assigned to it in this specific environment. This letter is often, but not always, `$C:$.

***

### 1. Launch the Disk Partitioning Tool

First, we need to open `diskpart`, the command-line utility for managing your computer's drives.

At the Command Prompt, type the following and press Enter:

```cmd
diskpart
```

Your prompt will change to `DISKPART>` to indicate you are now inside the tool.

### 2. Identify the Correct Physical Disk

Next, we'll list all physical disks the system can see to find the one containing your Windows installation.

> [!TIP] How to Identify Your Disk
> Look for the disk that matches the size of your main system drive (e.g., 256 GB, 512 GB, 1 TB). In most standard setups, this will be **Disk 0**.

Within the `DISKPART>` prompt, execute this command:

```cmd
list disk
```

Once you have identified the correct disk number from the list, select it. Replace `0` with the correct number for your system.

```cmd
select disk 0
```

> [!WARNING] Double-Check Your Selection
> Selecting the wrong disk can lead to data loss. Please verify the disk size and number before proceeding.

### 3. Pinpoint the Windows Volume

With the correct disk selected, we now need to find the specific volume (or partition) where Windows is installed.

To see all volumes on the selected disk, use the following command:

```cmd
list vol
```

> [!NOTE] Finding the Windows Volume
> Scan the output for your main Windows partition. You can typically identify it by:
> *   **Filesystem:** It will be `NTFS`.
> *   **Size:** It will be the largest partition on the disk.
> *   **Label:** It might have a label like "Windows" or "OS".
> *   **Letter (Ltr):** Note the drive letter assigned. It might be `$C:$, `$D:$, or another letter in this environment.

### 4. Record Your Findings

This final step is crucial for all subsequent operations.

> [!IMPORTANT]
> Take meticulous note of the drive letter assigned to your main Windows volume. For the remainder of our guides, we will refer to this letter as **`W:`**. You must substitute `W:` with the actual letter you identified (e.g., `$C:$, `$D:$, etc.).

