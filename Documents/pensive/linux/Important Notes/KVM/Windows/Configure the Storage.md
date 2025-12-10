# Optimizing Virtual Disk Performance

In this section, we will configure the virtual hard drive to ensure it runs as fast as possible and efficiently manages storage space on your host system.

### Step 1: Select the Storage Device

1. Open the virtual machine details view (the lightbulb icon) (if already opened, follown next step). 
    
2. From the left sidebar panel, locate and select **SATA Disk 1**.
    

### Step 2: Change the Disk Bus

1. In the right-hand details pane, look for the **Disk bus** dropdown menu.
    
2. Change the selection from `SATA` to `VirtIO`.
    

> [!INFO] Why VirtIO?
> 
> VirtIO is specifically designed for virtualization. Unlike SATA, which tries to emulate physical hardware (making the VM "think" it's a real hard drive), VirtIO allows the VM to know it is virtualized. This reduces overhead and significantly improves read/write speeds.

### Step 3: Configure Advanced Performance Options

1. Expand the **Advanced options** dropdown menu (usually located below the disk bus settings).
    
2. Locate the **Cache mode** setting and change it to `none`.
    

> [!NOTE] Understanding Cache Mode: None
> 
> Setting the cache to none bypasses the host's page cache.
> 
> - **How it works:** Input/Output (I/O) operations happen directly between the hypervisor and the storage device.
>     
> - **Benefit:** This offers performance almost equivalent to direct disk access on your physical machine and ensures data integrity.
>     

3. Locate the **Discard mode** setting and change it to `unmap`.
    

> [!TIP] Understanding Discard Mode: Unmap
> 
> This setting helps manage your hard drive space efficiently.
> 
> - **Without this:** If you delete a 10GB file inside the VM, the VM sees the space as free, but the actual file on your host computer (the `.qcow2` image) stays the same size.
>     
> - **With `unmap`:** When you delete files in the guest VM, the disk image on your host system automatically shrinks to reclaim that space.
>     

### Step 4: Save Changes

1. Click the **Apply** button at the bottom right of the window to save your configuration.
    

**Next Step:** Proceed to the next hardware configuration note.