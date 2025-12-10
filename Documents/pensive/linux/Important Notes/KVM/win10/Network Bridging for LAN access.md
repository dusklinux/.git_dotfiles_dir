To make the VM available on your LAN (Layer 2 visibility, getting an IP like `192.168.1.50`), you must move away from `virbr0` (NAT). You need to bridge your physical network card.
run on host: this see the output, you dont need to use virbro, it should be down. if no vm is using it currently. 
```bash
ip -br link show type bridge
```

**Crucial Check: Are you using Ethernet or Wi-Fi?** The solution is completely different for each.

---

> [!danger]
> Highly recommanded to switch to `Virtio` for `Device Model:` for every type of network. 
> eg 
> `Device Model:` `Virtio`

---

# IF YOU WANT TO SSH INTO GUEST FROM HOST

on the left hand side click
`NIC:xxxxx`

this will open on the right:
`Virtual Network Interface`
change network source to bridge
`Network source: Bridge device...`

 then run this command on host. 
 ```bash
 ip -br link show type bridge
 ```

expected output similar to this: 
```ini
ip -br link show type bridge
virbr0           DOWN           52:54:00:a9:b8:23 <NO-CARRIER,BROADCAST,MULTICAST,UP> 
```

all you need is the name ie `virbro0`
then go back to the virt manager and enter the name in the 
`Device Name:` box
eg `Device Name: virbr0`


---
---

# FOR LOCAL LAN ACCESS 

 (Ethernet is the best option!, BUT FOR WIFI THERE'S A LIMITIATION, HOST WONT BE ABLE TO ACCESS THE NETWORK BUT OTHER DEVICES ON THE SAME NETWORK WILL)
### Scenario A: You are using Ethernet (Recommended)

You need to create a **host bridge** (`br0`). This turns your PC's ethernet port into a "virtual switch" that both your Host and your VM plug into.

Since you are likely using **NetworkManager** (standard for Hyprland/Desktop setups), run these commands in your terminal. _Note: Replace `eth0` with your actual interface name found via `ip link`._


```bash
# 1. Create a bridge interface named 'br0'
nmcli con add type bridge ifname br0 con-name br0

# 2. Disable STP (Spanning Tree Protocol) to speed up connection (optional but recommended for simple setups)
nmcli con modify br0 bridge.stp no

# 3. Add your physical ethernet 'eth0' as a slave to this bridge
nmcli con add type bridge-slave ifname eth0 master br0

# 4. Bring up the bridge (Your network will restart)
nmcli con up br0
```


**After creating `br0`:**

1. Open **Virtual Machine Manager**.
    
2. Open your VM's hardware details -> **NIC**.
    
3. **Network source:** "Bridge device".
    
4. **Device name:** `br0`.
    
5. Start the VM. It will now request an IP directly from your physical router.


---


### Scenario B: You are using Wi-Fi

**You cannot bridge a standard Wi-Fi client connection.** The IEEE 802.11 standard (3-address mode) prevents an Access Point from accepting packets from a MAC address that didn't authenticate with it (i.e., your VM's MAC).

**The Workaround: Macvtap** This is a driver that simplifies virtualizing a physical interface.

- **Pros:** The VM gets its own LAN IP.
    
- **Cons:** **The Host cannot talk to the VM** (and vice versa) due to kernel limitations (hairpin mode), though other devices on the LAN _can_ see the VM.
    

**How to set up Macvtap:**

1. Open **Virtual Machine Manager**.
    
2. Go to the VM's **NIC** settings.
    
3. **Network source:** Select "Macvtap device".
    
4. **Device name:** Select your Wi-Fi card (e.g., `wlan0`).
    
5. **Source mode:** "Bridge".
    
6. Start the VM.
    

_If you absolutely need Host <-> VM communication on Wi-Fi, the setup becomes much more complex (routed networking or Proxy ARP)._

### Summary for your "Elite DevOps" Workflow

Since you are managing this via `virt-manager` but likely want to script/automate this later:

- **Ethernet?** Build a persistent `br0` via `nmcli` or `systemd-networkd`. This is the enterprise-grade standard.
    
- **Wi-Fi?** Use `macvtap` for quick LAN access, but be aware of the host isolation.