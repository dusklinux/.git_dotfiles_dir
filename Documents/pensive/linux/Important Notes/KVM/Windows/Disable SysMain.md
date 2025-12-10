
In a virtualized environment, minimizing background resource usage is critical for performance. **SysMain** (formerly known as SuperFetch) is a standard Windows feature designed to preload frequently used applications into memory.

> [!NOTE] Why disable this?
> 
> While useful on bare metal hardware with slow HDDs, in a VM environment, SysMain often consumes a significant amount of CPU and RAM as a background service without providing a tangible benefit. Disabling it frees up resources for your actual tasks.

### Instructions

Follow these steps inside your Windows Virtual Machine:

1. Open the Services Manager
    
    Click the run dialog (or press Win + R), type `services.msc`, and press Enter to open the Services window.
    
2. Locate the Service
    
    Scroll down the list of services until you find SysMain.
    
    - _Tip: You can press `S` on your keyboard to jump to the services starting with that letter._
        
3. Open Properties
    
    Right-click on SysMain and select Properties.
    
4. Disable the Service
    
    In the properties window, perform the following two actions to ensure it is completely disabled:
    
    1. **Startup type**: Change this from "Automatic" to **Disabled**. (This prevents it from turning on when you reboot).
        
    2. **Service status**: Click the **Stop** button if the service is currently running.
        
5. Save Changes
    
    Click Apply and then OK to close the window.
    

> [!SUCCESS] Done
> 
> SysMain is now permanently disabled for this Virtual Machine.