# Elite Remote Access: Manual Tailscale Teardown

> [!warning] Critical Warning
> 
> Performing a Reset or Uninstall while connected remotely via Tailscale (SSH) will cut your connection immediately. Ensure you have physical access or an alternative network route.

## 🟢 Option 1: Soft Disable

Use this if you just want to turn the VPN off temporarily but keep your IP and configuration saved.

```
# Bring the interface down
sudo tailscale down

# Stop the background service
sudo systemctl stop tailscaled

# Prevent starting on boot
sudo systemctl disable tailscaled
```

## 🟡 Option 2: Identity Reset (New IP)

Use this if you want to keep the software installed, but want to force the machine to register as a "new" device with a **fresh IP address**.

1. **Stop the Service:**
    
    ```
    sudo systemctl stop tailscaled
    ```
    
2. Nuke the State Data:
    
    The identity keys are stored in /var/lib/tailscale. Deleting this wipes the machine's memory of who it is.
    
    ```
    sudo rm -rf /var/lib/tailscale
    ```
    
3. **Restart:**
    
    ```
    sudo systemctl start tailscaled
    ```
    
4. Re-Authenticate:
    
    The machine is now a blank slate.
    
    ```
    sudo tailscale up --qr
    ```
    

## 🔴 Option 3: Nuclear Uninstall

Use this to completely remove all traces of Tailscale from your Arch system.

### 1. Stop & Remove Package

```
# Stop service
sudo systemctl stop tailscaled

# Remove package and dependencies
sudo pacman -Rns tailscale
```

### 2. Clean Configs

Remove the overrides we created during setup.

```
# Remove NetworkManager override
sudo rm /etc/NetworkManager/conf.d/96-tailscale.conf
sudo systemctl reload NetworkManager

# (Optional) Remove uinput persistence if you don't need it for other tools
sudo rm /etc/modules-load.d/uinput.conf
```

### 3. Clean Data

Remove logs, cache, and identity files.

```
sudo rm -rf /var/lib/tailscale
sudo rm -rf /var/cache/tailscale
```

### 4. Revert Firewall

Remove the rule allowing the interface.

**Firewalld:**

```
sudo firewall-cmd --zone=trusted --remove-interface=tailscale0 --permanent
sudo firewall-cmd --reload
```