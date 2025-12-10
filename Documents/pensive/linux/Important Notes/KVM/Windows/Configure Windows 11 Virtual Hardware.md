# Starting Virtual Machine Manager

## 1. Launch the Application

Open your application launcher (menu) and search for **Virtual Machine Manager** (often labeled as `virt-manager`).

> [!TIP] Pro Tip
> 
> If you cannot find the icon, you can launch it directly from your terminal by typing:
> 
> ```
> virt-manager
> ```

## 2. Enable XML Editing

**Critical Step:** Before creating a Windows 11 guest, we must enable advanced configuration options. This allows us to manually edit the virtual machine's configuration files (XML) to add specific Hyper-V enlightenments later on.

1. In the Virtual Machine Manager window, click on **Edit** in the top menu bar.
    
2. Select **Preferences**.
    
3. In the **General** tab, check the box labeled **Enable XML editing**.
    
4. Click **Close**.
    

> [!IMPORTANT]
> 
> If you skip this step, you will not be able to apply the specific optimizations required for this guide later in the process.

## 3. Start the Creation Wizard

Now that the environment is prepared, you can begin the setup process.

- Locate the **computer icon** in the upper-left corner of the toolbar.
    
- Hovering over this icon will display the tooltip: `Create a new virtual machine`.
    
- Click the icon to launch the **New VM Wizard**.
    

This wizard will guide you through the hardware allocation steps outlined in the next note.