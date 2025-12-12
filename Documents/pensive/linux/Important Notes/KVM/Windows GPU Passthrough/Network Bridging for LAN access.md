# KVM Networking Configuration

This guide covers how to configure the network interface for your Virtual Machine (VM). You will choose a configuration based on whether you want the VM to simply have internet access, or if you need it to appear as a separate physical device on your home network.

> [!ABSTRACT] Prerequisite Check
> 
> Before making changes, check the status of your internal bridges on the Host machine.
> 
> Run this in your terminal:
> 
> ```
> ip -br link show type bridge
> ```
> 
> _If no VMs are running, `virbr0` might be listed as `DOWN`. This is normal._

## 🚀 Performance Tip: Use Virtio

For **all** network types listed below, it is highly recommended to change the Device Model to `virtio`. This provides significantly better network performance than the default emulated cards (like e1000).

1. Open **Virtual Machine Manager**.
    
2. Open your VM -> **Show virtual hardware details** (the lightbulb icon).
    
3. Select the **NIC** (Network Interface) on the left.
    
4. Set **Device model** to: `virtio`.
    
---
## Option 1: Basic Internet (NAT)

**Use Case:** You just want the VM to have internet, and you want to SSH into the VM from _this_ computer (the Host). You do _not_ need other computers on your LAN to see the VM.

1. Open your VM hardware details.
    
2. Select **NIC** on the left.
    
3. Locate **Network source**.
    

- _Easiest Method:_ Select `Virtual network 'default' : NAT`.
    

---
# RECOMMENDED! this is both simple and achieves the best outcome. 
## Option 2: Manual Bridge Method: For Host Access: Manually specify the bridge interface:

1. Select **Bridge device**.
    
2. Run in a terminal to find your virtual bridge name (usually `virbr0`).
    

```
ip -br link show type bridge
```

3. In the **Device name** box, type: `virbr0` or what ever you find to be listed in output for previous command..
    
4. Click **Apply**.

>[!tip] If you there's no output to the command, run the fixing `errors steps` in [[Activating Network and Setting it to Autostart]]

---
## Option 3: Local LAN Access (Layer 2 Bridging)

**Use Case:** You want your VM to have its own IP address on your home network (e.g., `192.168.1.50`), just like your phone or laptop.

> [!WARNING] Crucial Decision
> 
> The setup differs completely depending on whether your Host computer is connected via Ethernet or Wi-Fi.

### Scenario A: You are using Wi-Fi

You cannot bridge a standard Wi-Fi connection due to technical limitations (IEEE 802.11 3-address mode). We must use a workaround called **Macvtap**.

> [!DANGER] Limitation Warning
> 
> The Host cannot talk to the VM.
> 
> Due to kernel limitations (hairpin mode), your Host computer will not be able to ping or SSH into the VM, and the VM cannot ping the Host.
> 
> However, other devices on your network (like your phone or another laptop) CAN communicate with the VM.

1. Open **Virtual Machine Manager**.
    
2. Go to the VM's **NIC** settings.
    
3. Change **Network source** to: `Macvtap device`.
    
4. In **Device name**, select your physical Wi-Fi card (e.g., `wlan0` or `wlp3s0`).
    
5. Set **Source mode** to: `Bridge`.
    
6. Start the VM.
    

### Scenario B: You are using Ethernet (Recommended)

You must create a **System Bridge** on your Host. This turns your PC's ethernet port into a "virtual switch."

#### Step 1: Create the Bridge (Run on Host)

Since you are likely using NetworkManager, run these commands.

Note: Replace `eth0` in the commands below with your actual interface name (find it by running `ip link`).

```bash
# 1. Create a bridge interface named 'br0'
nmcli con add type bridge ifname br0 con-name br0

# 2. Disable STP (Spanning Tree Protocol) to speed up connection
# (Optional, but recommended for simple home setups)
nmcli con modify br0 bridge.stp no

# 3. Add your physical ethernet 'eth0' as a slave to this bridge
nmcli con add type bridge-slave ifname eth0 master br0

# 4. CRITICAL: Ensure the slave connects automatically
# Without this, the bridge might come up empty on reboot
nmcli con modify br0 connection.autoconnect-slaves 1

# 5. Bring up the bridge (Your network will restart momentarily)
nmcli con up br0
```

#### Step 2: Configure the VM

1. Open **Virtual Machine Manager**.
    
2. Go to the VM's **NIC** settings.
    
3. Change **Network source** to: `Bridge device`.
    
4. In **Device name**, type: `br0`.
    
5. Start the VM. It will now request an IP directly from your physical router.
    

### Summary for Automation

If you plan to script this setup later:

- **Ethernet:** Build a persistent `br0` via `nmcli` (as shown above) or `systemd-networkd`. This is the enterprise-standard approach.
    
- **Wi-Fi:** Use `macvtap` for quick LAN access, accepting the host-isolation limitation.
    

## 🆘 Disaster Recovery: Reverting Bridge Settings

If Option 3 (Ethernet Bridge) fails and you lose internet connectivity on the host, run these commands to delete the bridge and restore your default connection.

```
# 1. Bring down the bridge
sudo nmcli connection down br0

# 2. Delete the bridge definition
sudo nmcli connection del br0

# 3. Delete the slave definition (the link between eth0 and br0)
# (Name may vary, check 'nmcli con show')
sudo nmcli connection del bridge-slave-eth0 

# 4. Bring your original wired connection back up
# (Replace 'Wired connection 1' with your actual connection name)
sudo nmcli connection up 'Wired connection 1'
```