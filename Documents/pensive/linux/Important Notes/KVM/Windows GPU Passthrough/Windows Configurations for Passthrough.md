
Download the Windows Host Binary

or download from github










DONT EVER TURN OFF THE NVIDIA DISPLAY DRIVER AND VIRTUAL DISPLAY DRIVER. IF YOU HAVE TWO VIRTUAL DISPLAYE DRIVERS, DISABLE ONE AND CHECK IF YOU DISABLED THE RIGHT ONE. IF NOT, THEN RESTART AND TRY AGAIN. 

VirtIO-FS Service will only show up when virtio iso is installed. 

sometimes the cursor disappears when virtio is enabled, in which case uninstall, and then reinstall once viewing the vm from looking glass. 

turn on remotecontrol 



---
# **OPTIONAL,** Recommended to skip. 
# these are only needed for xfreerdp3 access. 
Perform these in Virt-Manager (SPICE console):

1. **Set a Password:** Windows Security Policy blocks RDP for empty passwords. Set a password for user `dusk or whatever`.
    
2. **Enable Remote Desktop:** Settings > System > Remote Desktop > **ON**.
    
3. **Check IP:** Run `ipconfig` in Powershell (e.g., `192.168.122.29`).
---