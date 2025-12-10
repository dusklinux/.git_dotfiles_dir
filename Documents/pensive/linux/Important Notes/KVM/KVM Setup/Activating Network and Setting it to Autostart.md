# KVM Default Network Configuration

By default, all virtual machines (VMs) on your host are connected to a virtual network named **'default'**. This network uses **NAT** (Network Address Translation) to allow your VMs to talk to the outside world.

> [!INFO] What is NAT?
> 
> Think of NAT like your home router.
> 
> - **Outbound:** Your VMs can browse the internet, download updates, and ping external servers.
>     
> - **Inbound:** Devices outside your computer (like your phone or another laptop) _cannot_ see or connect to the VMs directly.
>     
> 
> This is perfect for desktop usage (browsing, testing) but not for hosting public servers.

## 1. Check Network Status

First, let's verify if the default network is active. Open your terminal and run:

```
sudo virsh net-list --all
```

**Expected Output:**

| **Name** | **State**  | **Autostart** | **Persistent** |
| -------- | ---------- | ------------- | -------------- |
| default  | **active** | **yes**       | yes            |

## 2. Start the Network

If the state is **inactive** or Autostart is set to **no**, you need to turn it on. This creates a virtual network bridge (usually called `virbr0`) that acts as the gateway for your VMs.

Run the following to start it immediately and ensure it starts automatically on boot:

```bash
# Start the network immediately
sudo virsh net-start default

# Ensure it starts every time you boot your computer
sudo virsh net-autostart default
```

> [!WARNING] No Internet?
> 
> If you skip this step, your Virtual Machines will have no internet connection.

## 3. Advanced: Verifying IP Ranges

It is helpful to know what IP addresses your VMs will get. The 'default' network acts as a DHCP server (it hands out IP addresses automatically).

To see the configuration, run this command:

```bash
sudo virsh net-dumpxml default
```

Look for the `<ip>` section in the output. It will look something like this:

```bash
<ip address="192.168.124.1" netmask="255.255.255.0">
  <dhcp>
    <range start="192.168.124.2" end="192.168.124.254"/>
  </dhcp>
</ip>
```

**What this tells you:**

- **Host IP:** `192.168.124.1` (This is your host computer's address _inside_ the virtual network).
    
- **DHCP Range:** Your VMs will be assigned random addresses between `.2` and `.254`.
    

> [!TIP] Need external access?
> 
> If you need devices on your physical LAN to communicate directly with your VMs (e.g., hosting a web server accessible to others), NAT will not work.
> 
> Refer to [[Network Bridging for LAN access]] to set up a full Bridge connection.