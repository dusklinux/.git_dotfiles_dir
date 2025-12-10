# Resizing a Windows VM Disk

This guide details how to increase the storage capacity of your Windows Virtual Machine. It involves two main phases: expanding the virtual disk file on your Linux host, and then expanding the partition inside Windows.

> [!WARNING] CRITICAL: Shutdown Required
> 
> Do not attempt to resize the disk while the Virtual Machine is running or suspended.
> 
> 1. Shut down the Windows VM completely.
>     
> 2. Verify it is off in Virt-Manager (status should be "Shutoff").
>     
> 
> modifying a live qcow2 image can result in **permanent data corruption**.

## Part 1: Resize the Disk Image (Linux Host)

Perform these steps in your Arch Linux terminal.

### 1. Locate your Disk Image

If you aren't 100% sure of your disk path, use this command to list all disks attached to your VMs. Look for your Windows VM name:

```bash
sudo virsh list --all
```

```
virsh domblklist <vm-name>
```

### 2. Add Space to the Image

Use the `qemu-img resize` command to add storage.

- **Syntax:** `sudo qemu-img resize <path_to_image> +<size>G`
    
- **Example:** To add **20 Gigabytes** to the specific path you configured.
    

```
# Add 20GB to the Windows 10 image
sudo qemu-img resize /mnt/slow/documents/kvm/win10/win10.qcow2 +20G
```

> [!TIP] Verification
> 
> You can verify the new size was applied by running:
> 
> qemu-img info /mnt/slow/documents/kvm/win10/win10.qcow2

## Part 2: Extend the Partition (Windows Guest)

Now that the "physical" disk is larger, you must tell Windows to use the new space.

1. **Power On** your Windows 10 VM.
    
2. **Open Disk Management**:
    
    - Right-click the **Start Button** (bottom left Windows logo).
        
    - Select **Disk Management**.
        
3. **Locate the Space**:
    
    - Look for your `(C:)` drive.
        
    - Immediately to the right of it, you should see a block labeled **Unallocated** (black bar).
        
4. **Extend the Volume**:
    
    - Right-click the **(C:)** partition.
        
    - Select **Extend Volume...**
        
    - Click **Next** on the wizard.
        
    - It will automatically select all the new unallocated space. Click **Next**, then **Finish**.
        

> [!SUCCESS] Done
> 
> Your C: drive should now reflect the larger size immediately.

## Troubleshooting: "Extend Volume" is Grayed Out

> [!BUG] The Issue
> 
> If Extend Volume is grayed out, there is likely a Recovery Partition sitting between your C: drive and the Unallocated space. Windows cannot skip over partitions to extend storage.

You have two options to fix this.

### Option A: Use GParted (Recommended/Safer)

The safest way to move the partition without deleting it is to use a Linux live ISO.

1. Download the **GParted Live ISO**.
    
2. Attach it to your VM's CDROM in Virt-Manager and boot from it.
    
3. Use the GParted GUI to **move** the Recovery Partition to the end of the disk (drag and drop).
    
4. Reboot into Windows and extend normally.
    

### Option B: Delete the Recovery Partition (Faster/Destructive)

If you do not want to download GParted and don't mind losing the built-in Windows Recovery Environment (WinRE), you can delete the blocking partition using the command line.

> [!DANGER] Warning
> 
> This removes your ability to use "Reset this PC" or boot into recovery mode until a new recovery partition is created.

1. Inside the Windows VM, right-click Start and select **Windows PowerShell (Admin)** or **Command Prompt (Admin)**.
    
2. Type `diskpart` and press Enter.
    
3. Run the following commands strictly in order:
    

```
list disk
select disk 0       # (Assuming Disk 0 is your main drive)
list partition      # Note the number of the "Recovery" partition (usually approx 500MB)
select partition X  # Replace X with the Recovery partition number found above
delete partition override
exit
```

4. Go back to **Disk Management**. The obstruction is gone, and you can now Right-click **(C:)** -> **Extend Volume**.