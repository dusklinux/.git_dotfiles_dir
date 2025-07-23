# Accessing BitLocker Drives on Arch Linux

This guide provides a step-by-step process for unlocking and mounting a BitLocker-encrypted drive on Arch Linux. We will use the `cryptsetup` utility, a powerful and standard tool for managing encrypted volumes in Linux.

> [!NOTE] Why `cryptsetup`?
> While tools like `dislocker` exist, `cryptsetup` offers a more integrated and modern approach, leveraging the kernel's device-mapper framework directly for better performance and stability.

---

## Step 1: Identify the BitLocker Drive

First, you must identify the device name of your BitLocker-encrypted partition. You can do this by listing all block devices connected to your system.

> [!TIP]
> For more detailed information on identifying disks, you can refer to the [[Disk Partitioning]] note.

```bash
lsblk
```

Look for the partition that corresponds to your BitLocker drive. It will likely be an `ntfs` partition, and you can identify it by its size and label. For this guide, we will assume the drive is `/dev/sdXn`.

## Step 2: Unlock the Drive

With the device identified, use `cryptsetup` to unlock it. This command will prompt you for your BitLocker recovery key or password and create a decrypted mapping of the device in `/dev/mapper/`.

```bash
sudo cryptsetup bitlkOpen /dev/<drive> bitlk_device
```

> [!ATTENTION] Command Breakdown
> - `/dev/<drive>`: Replace this with your target partition (e.g., `/dev/sdb1`).
> - `bitlk_device`: This is a temporary name you choose for the unlocked device mapper. You can name it anything, but using a descriptive name is good practice.

After running this command, you will be prompted to enter your BitLocker password.

## Step 3: Mount the Unlocked Drive

Once unlocked, the decrypted volume is available at `/dev/mapper/bitlk_device`. To access the files, you must mount this mapped device to a directory on your system.

#### 1. Create a Mount Point

First, create a directory that will serve as the mount point. A common location is within the `/mnt` directory.

```bash
sudo mkdir /mnt/bitlk
```

#### 2. Mount the Filesystem

Now, mount the unlocked device to the directory you just created.

```bash
sudo mount /dev/mapper/bitlk_device /mnt/bitlk
```

Your files are now accessible at `/mnt/bitlk`.

## Step 4: Clean Up (Unmount and Close)

When you are finished accessing the files, it is crucial to properly unmount and close the encrypted device to ensure data integrity and security.

> [!WARNING] Important
> Always perform these cleanup steps before physically disconnecting the drive. Failure to do so can result in data corruption.

#### 1. Unmount the Drive

First, unmount the filesystem from your mount point.

```bash
sudo umount /mnt/bitlk
```

#### 2. Close the Encrypted Device

Finally, close the `cryptsetup` mapping to lock the drive.

```bash
sudo cryptsetup close bitlk_device
```

The drive is now securely locked and can be safely disconnected.

---

### Quick Reference

| Action | Command |
|---|---|
| **Unlock Drive** | `sudo cryptsetup bitlkOpen /dev/<drive> bitlk_device` |
| **Create Mount Point** | `sudo mkdir /mnt/bitlk` |
| **Mount Drive** | `sudo mount /dev/mapper/bitlk_device /mnt/bitlk` |
| **Unmount Drive** | `sudo umount /mnt/bitlk` |
| **Close/Lock Drive** | `sudo cryptsetup close bitlk_device` |
