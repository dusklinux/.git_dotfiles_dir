shutdown the vm completely and then run this in the terminal

make sure to specify the right path 

```bash
# Add (for example) 20 GiB:
sudo qemu-img resize /mnt/slow/documents/kvm/win10/win10.qcow2 +20G
```


Part 2: Extend the Partition in Windows 10

After increasing the virtual disk size, the new space will be visible to Windows as "Unallocated space." You need to extend your existing C: drive to use this new space.[1][3]

    Start the Virtual Machine: Power on your Windows 10 VM.

    Open Disk Management:

        Right-click the Start button and select "Disk Management".[5][6]

        You should see your primary partition (usually C:) followed by the unallocated space.[1]

    Extend the Volume:

        In Disk Management, right-click the C: drive (or the primary volume you want to extend) and select "Extend Volume".[6][7]

        The "Extend Volume Wizard" will open. Click "Next".[7]

        The wizard will automatically select the available unallocated space. Confirm the amount of space you want to add and click "Next", then "Finish".[5][7]

Troubleshooting: "Extend Volume" is Grayed Out

Sometimes, a recovery partition can be located between your main partition and the new unallocated space, preventing you from extending the volume.[3][8] If the "Extend Volume" option is grayed out, you will need to move this recovery partition.

You can address this in a couple of ways:

    Use a third-party partition tool: Tools like GParted (as a bootable ISO) or MiniTool Partition Wizard can be used to move the recovery partition to the end of the disk, making the unallocated space adjacent to your C: drive.[8]

    Delete and recreate the recovery partition (Advanced): This involves using the diskpart command-line utility within Windows to delete the recovery partition, extend the main partition, and then recreate a new recovery partition in the remaining space.[3][8] This is a more complex procedure and should be done with caution.