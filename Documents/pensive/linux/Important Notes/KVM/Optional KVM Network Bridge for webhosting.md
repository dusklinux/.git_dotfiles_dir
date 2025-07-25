Virtual machines using this default network will only have outbound network access. Virtual machines will have full access to network services, but devices outside the host will be unable to communicate with virtual machines inside the host. For example, the virtual machine can browse the web but cannot host a web server that is accessible to the outside world.

If you want virtual machines to be directly visible on the same physical network as the host and visible to external devices, you must use a network bridge.

A network bridge is a link-layer device that connects two local area networks into one network. In this case, a software bridge is used within a Linux host to simulate a hardware bridge. As a result, all other physical machines on the same physical network of the host can detect and access virtual machines. The virtual machine, for example, can browse the web, and will also be able to host a web server that is accessible to the outside world.

> [!Important] Unfortunately, you cannot set up a network bridge when using Wi-Fi.

Due to the IEEE 802.11 standard which specifies the use of 3-address frames in Wi-Fi for the efficient use of airtime, you cannot configure a bridge over Wi-Fi networks operating in Ad-Hoc or Infrastructure modes.

First, find the name of the interface you want to add to the bridge. In my case, it is enp2s0.

```bash
sudo nmcli device status
```

| DEVICE | TYPE | STATE | CONNECTION |
| ------ | ---- | ----- | ---------- |
|enp2s0 | ethernet |  connected | Wired connection 1 |
|lo | loopback | connected (externally)|  lo |                
|virbr0 | bridge | connected (externally) | virbr0 |

Create a bridge interface. I'll name it bridge0, but you can call it whatever you want.

```bash
sudo nmcli connection add type bridge con-name bridge0 ifname bridge0
```

Assign the interface to the bridge. I'm going to name this connection 'Bridge connection 1', but you can call it whatever you want.

```bash
sudo nmcli connection add type ethernet slave-type bridge \
con-name 'Bridge connection 1' ifname enp2s0 master bridge0
```

The following step is optional. If you want to configure a static IP address, use the following commands; otherwise, skip this step. Change the IP address and other details to match your configuration.

$ sudo nmcli connection modify bridge0 ipv4.addresses '192.168.1.7/24'
$ sudo nmcli connection modify bridge0 ipv4.gateway '192.168.1.1'
$ sudo nmcli connection modify bridge0 ipv4.dns '8.8.8.8,8.8.4.4'
$ sudo nmcli connection modify bridge0 ipv4.dns-search 'sysguides.com'
$ sudo nmcli connection modify bridge0 ipv4.method manual

Activate the connection.

```bash
sudo nmcli connection up bridge0
```

Enable the connection.autoconnect-slaves parameter of the bridge connection.

```bash
sudo nmcli connection modify bridge0 connection.autoconnect-slaves 1
```

Reactivate the bridge.

```bash
sudo nmcli connection up bridge0
```

Verify the connection. If you get your IP address from DHCP, it may take a few seconds to lease a new one. So please be patient.

```bash
sudo nmcli device status
```

DEVICE             TYPE      STATE                   CONNECTION          
bridge0            bridge    connected               bridge0             
lo                 loopback  connected (externally)  lo                  
virbr0             bridge    connected (externally)  virbr0              
enp2s0             ethernet  connected               Bridge connection 1

```bash
ip -brief addr show dev bridge0
```
bridge0          UP             192.168.1.7/24 fe80::a345:fb7b:cb67:c778/64

You can now start using a network bridge when creating virtual machines.

However, it is recommended that you also set up a virtual bridge network in KVM so that the virtual machines can use this bridge interface by name.

Create an XML file called nwbridge.xml and fill it with the following information. I'll call my host network bridge nwbridge, but you can call it whatever you want.

```bash
nvim nwbridge.xml
```

```ini
<network>
  <name>nwbridge</name>
  <forward mode='bridge'/>
  <bridge name='bridge0'/>
</network>
```

Define nwbridge as a persistent virtual network.

```bash
sudo virsh net-define nwbridge.xml
```

Activate the nwbridge and set it to autostart on boot.

```bash
sudo virsh net-start nwbridge
sudo virsh net-autostart nwbridge
```

Now you can safely delete the nwbridge.xml file. It’s not required anymore.

```bash
rm nwbridge.xml
```

Finally, verify that the virtual network bridge nwbridge is up and running.

```bash
sudo virsh net-list --all
```

 Name       State    Autostart   Persistent
---------------------------------------------
 default    active   yes         yes
 nwbridge   active   yes         yes

A network bridge has been created. You can now start using the nwbridge network bridge in your virtual machines. The virtual machines will get their IP addresses from the same pool as your host machine.

If you ever want to remove this network bridge and return it to its previous state, then run the following commands.

```bash
sudo virsh net-destroy nwbridge
sudo virsh net-undefine nwbridge
sudo nmcli connection up 'Wired connection 1'
sudo nmcli connection down bridge0
sudo nmcli connection del bridge0
sudo nmcli connection del 'Bridge connection 1'
```