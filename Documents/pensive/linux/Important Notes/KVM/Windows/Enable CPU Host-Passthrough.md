# CPU Configuration

> [!ABSTRACT] Goal
> 
> Configure the Virtual Machine to utilize the full power of your physical processor.

### 1. Access Hardware Details

If you are currently looking at the console (screen) or the XML editing tab, you need to switch to the hardware view.

- Click the **Details** button in the top toolbar of the Virtual Machine window.
    

### 2. specific CPU Settings

- In the left-hand sidebar panel, select **CPUs**.
    
- Look for the **Configuration** area.
    
- Ensure the **Model** or **Configuration** mode is set to: `host-passthrough`.
    **Copy host CPU configuration (host-passthrough)**

> [!TIP] Why host-passthrough?
> 
> When the mode is set to host-passthrough, the host CPU's model and features are exactly passed on to the guest virtual machine (the OS you are installing).
> 
> - **Performance:** This causes the virtual machine to run close to the host's native speed.
>     
> - **Recommendation:** This is the default and highly recommended option for best performance.
>     

### 3. Save

- Click **Apply** at the bottom right of the window.