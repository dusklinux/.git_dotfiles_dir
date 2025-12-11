The RDP method to disable display driver
## 🔄 Phase 3: The "Headless" Switch


Pre requistis, 
If you have a custom iso for whom remote desktop is ripped out, this rdp method wont work. go back and use the other method, (my custom win 10 iso has it ripped out , for win11 i somereason didnt rip it out. so win11 works. )
### Remote Desktop (RDP) Configuration

> [!example]- OPTIONAL: Advanced Setup (Click to Expand)
> 
> Recommended to skip. These steps are only required if you intend to access this VM via xfreerdp3 instead of Looking Glass.
> 
> Perform these steps inside the standard Virt-Manager (SPICE) console:
> 
> 1. Set a User Password:
>     
>     Windows Security Policy blocks RDP connections for accounts with empty passwords. Set a password for your user (e.g., User dusk).
>     
> 2. Enable Remote Desktop:
>     
>     Go to Settings > System > Remote Desktop and toggle it ON.
>     
> 3. Identify IP Address:
>     
>     Open PowerShell and run:
>     
>     ```
>     ipconfig
>     ```
>     
>     Note the IPv4 address (e.g., `192.168.122.29`).
>
### 1. you must know your ip address for windows, check taskmanager, 
### 2. you must have a password set for the user, and know both your user name and password for windows. (you can also do it without it if you have access t group policy , )

> [!NOTE]
> **Option B: Allow Blank Passwords (The "I hate passwords" way)**
> - Press `Win + R`, type `secpol.msc`, and hit Enter.
> - Go to **Local Policies** -> **Security Options**.
> - Find: **"Accounts: Limit local account use of blank passwords to console logon only"**.
> - Double-click it and set it to **Disabled**.

### 3. You must have remote desktop enabled in settings.
	In Windows, go to **Settings > System > Remote Desktop**.
### 4. you must have your network set to private instead of public. 


This is the most critical step. We must disable the Emulated GPU ("Microsoft Basic Display" or "Red Hat QXL") to force Windows to use the Passthrough NVIDIA GPU.

> [!warning] Don't do this inside Virt-Manager!
> 
> If you disable the display adapter while looking at it through Virt-Manager, your screen will freeze, and you will lose mouse control. We must use RDP first.

### 1. Connect via RDP (The Rescue Line)

1. Get your VM's IP address (check your router or `ipconfig` inside the VM if you can see it). or from network section of the Task manager
    
2. Run this command from your Arch terminal:
    
### Replace 192.168.122.29 with YOUR VM IP
### Replace 'dusk' with YOUR Windows Username
```bash
xfreerdp3 /v:192.168.122.29 /u:dusk /cert:ignore /dynamic-resolution
```

>[!tip] A new window will open with your vm's screen. 
### 2. Disable the Basic Adapter

**Inside the RDP Session:**

1. Open **Device Manager**.
    
2. Expand **Display Adapters**.
    
3. Right-click **Microsoft Basic Display Adapter** (or Red Hat QXL).
    
4. Select **Disable Device**.
    