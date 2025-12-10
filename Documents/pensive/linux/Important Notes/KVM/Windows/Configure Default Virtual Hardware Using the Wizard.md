# Creating the Virtual Machine: The Wizard

The Virtual Machine Manager (Virt-Manager) wizard allows you to quickly scaffold a guest virtual machine. In this section, we will configure the initial settings to ensure your Windows VM runs smoothly.

Follow these steps exactly to prepare the environment.

### Step 1: Installation Source

Open Virt-Manager and click the **Create New Virtual Machine** icon. You will be asked how you would like to install the operating system.

1. Select **Local install media (ISO image or CDROM)**.
    
2. Click **Forward**.
    

### Step 2: ISO Selection

You must now locate the Windows ISO file you downloaded earlier.

1. Click **Browse** and then > in the new window popup **Browse Local**.
    
2. Navigate through your file manager to the directory where your `.iso` file is saved and double-click it.
    

> [!WARNING] Automatic Detection Issues
> 
> Sometimes Virt-Manager fails to automatically detect that the ISO especially if it's a custom iso or a neiche OS.
> 
> 1. Uncheck **Automatically detect from the installation media / source**.
>     
> 2. In the search box, type `Windows 10/11`.
>     
> 3. Select `Microsoft Windows 10/11` from the dropdown list.
> **Note:** Do not type the OS name manually; you _must_ select the official entry from the list to ensure proper defaults are loaded.
> 
Click **Forward**.

### Step 3: CPU and Memory

Assign the hardware resources from your physical computer (Host) to the virtual machine (Guest).

- **Memory (RAM):** Recommended at least `4096` MiB (4GB) for windows 10 , though `8192` MiB (8GB) is preferred for Windows 11.
    
- **CPUs:** Assign at least `2` cores.
    

Click **Forward**.

### Step 4: Storage Configuration

We need to create a specific virtual hard drive for this machine.

1. Select **Select or create custom storage**.
    
2. Click the **Manage** button.
    

This opens the Storage Volume selection window. We will create a specific location for your VM files.

> [!INFO] Key Concepts
> 
> - **Pool:** The actual folder (directory) on your computer where files live.
>     
> - **Volume:** The specific file inside that folder that acts as the hard drive for the VM.
>     

#### 4a. Create the Storage Pool

1. Click the **+ (Plus)** icon at the bottom left of the window (Tooltip: _Add Pool_).
    
2. **Name:** Give it a name, e.g., `pool_test` (or `windows-pool`).
    
3. **Type:** Select `dir: Filesystem Directory`.
    
4. **Target Path:** Browse to the folder where you want to save the VM image (e.g., your external WD hard disk).
    
5. Click **Finish**.
    

#### 4b. Create the Storage Volume

On the left sidebar, click the Pool you just created to select it. Now we create the disk image inside it.

1. Click the **+ (Plus)** icon in the main center area, right next to the label "Volumes".
    
2. **Name:** `win11-disk` (or similar).
    
3. **Format:** Select `qcow2`.
    
4. **Capacity:** Set this to at least 40 GB for win 10 or `64` GiB (Windows 11 minimum requirement).
    

![[Pasted image 20250726180159.png]]

> [!TIP] Understanding QCOW2 & Allocation
> 
> QCOW2 is a "Copy On Write" format. It is smart storage.
> 
> - **Important:** Ensure **Allocate entire volume now** is **UNCHECKED**.
>     
> - This is called "Thin Provisioning." Even if you set the size to 64GB, the file will start very small (a few MBs) and only grow as you actually install things on Windows.
>     

5. Click **Finish**. (This may take a moment).
    
6. With your new volume highlighted, click **Choose Volume**.
    
7. Back at the wizard screen, click **Forward**.
    

### Step 5: Finalization

This is the final configuration screen.

1. **Name:** Name your VM (e.g., `Win10`).
    
2. **Crucial Step:** Check the box that says ✅ **Customize configuration before install**.
    

> [!DANGER] Do not skip this!
> 
> You must check "Customize configuration before install". We need to manually add settings in the next section

You can leave network as is, we'll be configuring it in the next section. 

Click **Finish**.