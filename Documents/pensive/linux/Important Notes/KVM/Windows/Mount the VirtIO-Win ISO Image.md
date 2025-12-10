## Mounting the VirtIO Drivers ISO

> [!INFO] What are VirtIO Drivers?
> 
> VirtIO drivers are paravirtualized drivers that allow KVM guests (your Virtual Machine) to communicate efficiently with the host hardware.
> 
> **The Problem:** unlike Linux, **Microsoft Windows** does not come with these drivers pre-installed. Without them, the VM won't be able to see your hard drive or access the network properly.
> 
> **The Solution:** We must mount a "virtual CD" containing these drivers so Windows can install them.

### Prerequisites

> [!CHECK] Check your downloads
> 
> The virtio-win.iso file should have already been downloaded in one of the earlier steps.

### Instructions

We need to add a **second** CDROM drive to the Virtual Machine. The first one holds the Windows Installer, and this second one will hold the drivers.

1. Open your Virtual Machine details view in **Virt-Manager**.
    
2. Click the **Add Hardware** button (usually located at the bottom left depending on your version).
    
3. In the left sidebar, select **Storage**. (Usually the first option)
    
4. Configure the storage settings as follows:
    
    - **Device Type:** Change this to `CDROM device`.
        
5. Under "Select or create custom storage", click the **Manage...** button.
    
6. Locate the `virtio-win.iso` image file.
    
    - It is usually listed under the `default` storage pool.
        
    - Select the file and click **Choose Volume**.
        

> [!TIP] Can't find the ISO?
> 
> If the file isn't listed in the default pool, you may need to browse for the specific path where paru installed it.
> 
> Common locations on Arch Linux include:
> 
> - `/var/lib/libvirt/images/`
>     
> - `/usr/share/virtio-win/`
>     Or download it [[VirtIO win driver iso]]

7. Once selected, click **Finish**.
    

You should now see a second CDROM device appear in your hardware list on the left side.

8. Click **Apply** to ensure all changes are saved.