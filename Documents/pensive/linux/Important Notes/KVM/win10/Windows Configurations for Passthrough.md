Downlaod Virtual- Display-Driver from github

>[!INFO] and only install it ONCE! or you'll have multiple virtual displays. 

downlaod and install VDD from github. 
```http
https://github.com/VirtualDrivers/Virtual-Display-Driver
```

vdd has a c++ dependancy 
 Microsoft Visual C++ Redistributable
```http
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist
```


Download the Windows Host Binary
```http
https://looking-glass.io/downloads
```
or download from github
```http
https://github.com/gnif/LookingGlass
```


```http
https://www.oo-software.com/en/download/current/ooshutup10
```

```http
https://www.nvidia.com/en-us/drivers/
```

```http
https://www.7-zip.org/
```

```http
https://www.majorgeeks.com/files/details/windows_update_minitool.html
```


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