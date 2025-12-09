All the virtual machines on the host are by default connected to the same NAT-type virtual network, named 'default'.

```bash
sudo virsh net-list --all
```

This will be the output when you run it

| Name    | State  | Autostart | Persistant |
| ------- | ------ | --------- | ---------- |
| default | active | yes       | yes        |

if it's inactive and is not set to autostart you can do so with 
start the "Default" network. This creates a virtual bridge (usually `virbr0`) that NATs traffic from your VM to the outside world.
Without this, your VM will have no internet connection._
```bash
sudo virsh net-start default
sudo virsh net-autostart default
```



Virtual machines using this default network will only have outbound network access. Virtual machines will have full access to network services, but devices outside the host will be unable to communicate with virtual machines inside the host. For example, the virtual machine can browse the web but cannot host a web server that is accessible to the outside world.
Refer to [[KVM Network Bridge for webhosting]] to allow two way network traffic. 


### Dont really know what this does and it doesn't work on arch anyway. 

The virtual machines that use this 'default' network will be assigned an IP address in the `192.168.124.0/24` address space, with the host OS reachable at `192.168.124.1`

```bash
sudo virsh net-dumpxml default | xmllint --xpath '//ip' -
<ip address="192.168.124.1" netmask="255.255.255.0">
    <dhcp>
      <range start="192.168.124.2" end="192.168.124.254"/>
    </dhcp>
</ip>
```