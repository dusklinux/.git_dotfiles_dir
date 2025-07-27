# Fixing the Windows Boot Menu (UEFI)

This guide outlines a method to control where Windows creates the EFI System Partition (ESP) during a manual boot repair. This is particularly useful when you want the partition in a specific location on a disk with multiple unallocated spaces.

## The Challenge: Unpredictable EFI Partition Placement

When using Windows recovery tools to repair the bootloader, the system automatically searches for unallocated space to create a new EFI partition. If multiple unallocated sections exist on the drive, Windows may choose an undesirable location, leading to a disorganized partition layout.

## The Solution: Forcing the Location

The strategy is to force the Windows repair process to use a specific block of unallocated space by making it the *only* available option. We achieve this by temporarily formatting all other unallocated areas with a filesystem that Windows cannot recognize.

### Step-by-Step Guide

> [!WARNING] Modifying partitions can lead to data loss. Always back up important data before proceeding. This process should be performed using a partition management tool from a live environment (e.g., a Linux Live USB with GParted).

1.  **Prepare the Target Location**
    Using a tool like **GParted**, create a small, unallocated space (e.g., 500 MB) on the disk precisely where you want the new EFI partition to be.

2.  **Conceal Other Unallocated Spaces**
    Identify any other unallocated spaces on the same disk. To prevent Windows from using them, format each of these spaces with a filesystem it won't recognize.

> [!TIP] Choosing a Filesystem
> A Linux filesystem like `F2FS` or `ext4` is an excellent choice, as the Windows installer will ignore it and see the space as unusable.

3.  **Perform the Windows Boot Repair**
    With the disk prepared, boot into the Windows Recovery Environment and run the necessary commands to repair the bootloader. Since the tool can only see one valid unallocated space, it will be forced to create the EFI partition in the location you designated.

> [!important] Makes sure to revert changes to the unallocated partitions after you're done. 

3.  **Clean Up**
    After the bootloader is successfully repaired and Windows boots correctly, you can boot back into your live environment. Use GParted to delete the temporary partitions (e.g., the `F2FS` ones) to return them to unallocated space, which you can then merge or use as needed.