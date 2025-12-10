# Optional: Relocating Storage to ZRAM

> [!info] Objective
> 
> This step changes the default storage location for Virtual Machines from your physical hard drive to your RAM (ZRAM).
> 
> Why do this? > 1. Speed: RAM is significantly faster than any SSD.
> 
> 2. Hardware Health: It prevents "wear and tear" (write cycles) on your SSD, which is great for testing operating systems you don't intend to keep.

> [!danger] CRITICAL WARNING
> 
> ZRAM is Volatile Memory. > Anything you install or save into this specific storage pool WILL BE DELETED when you turn off or restart your computer.
> 
> Only follow this step if you are creating a temporary Virtual Machine (like a test environment) that you do not need to save.

### The Process

By default, KVM/QEMU stores virtual hard drives in `/var/lib/libvirt/images`. We are going to delete that folder and replace it with a "shortcut" (symbolic link) that points to your ZRAM drive.

Copy and run the following block in your terminal:

```bash
# 1. Remove the default image directory 
# (Note: This assumes the directory is empty. If it fails, ensure no VMs are currently defined)
sudo rmdir /var/lib/libvirt/images

# 2. Create the new directory inside your ZRAM mount point
# We use sudo here because /mnt usually belongs to the root user
sudo mkdir -p /mnt/zram1/os/

# 3. Create the Symbolic Link
# This tricks the system into thinking the ZRAM folder is actually the standard libvirt folder
sudo ln -nfs /mnt/zram1/os/ /var/lib/libvirt/images 
```

### Verification

To make sure the link was created successfully, you can run:

```
ls -la /var/lib/libvirt/
```

You should see an arrow -> pointing images to your ZRAM location:

images -> /mnt/zram1/os/