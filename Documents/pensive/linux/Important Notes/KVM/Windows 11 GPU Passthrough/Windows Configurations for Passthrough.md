Phase 3: Guest Configuration (Windows 11)

We must prepare Windows to output video to a monitor that doesn't physically exist.

### 1. Windows Pre-requisites

Perform these in Virt-Manager (SPICE console):

1. **Set a Password:** Windows Security Policy blocks RDP for empty passwords. Set a password for user `dusk or whatever`.
    
2. **Enable Remote Desktop:** Settings > System > Remote Desktop > **ON**.
    
3. **Check IP:** Run `ipconfig` in Powershell (e.g., `192.168.122.29`).
    
4. **Install Software:**
    
    - **NVIDIA Drivers:** Standard GeForce drivers.
        
    - **Looking Glass Host:** From [looking-glass.io](https://looking-glass.io/downloads). Ensure the service starts.
        
    - **Virtual Display Driver (IDD):** From [GitHub](https://github.com/VirtualDrivers/Virtual-Display-Driver). This allows us to create a fake monitor.
        
5. Set GPU Graphics to Nvidia under display/graphics settings. 