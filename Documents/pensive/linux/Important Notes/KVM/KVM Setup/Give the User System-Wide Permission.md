
Libvirt provides two methods for connecting to the local qemu-kvm hypervisor.

Connect as a regular user to a per-user instance locally. This is the default mode when running a virtual machine as a regular user. This allows users to only manage their own virtual machines.

```bash
virsh uri
```

qemu:///session

Connect to a system instance as the root user locally. When run as root, it has complete access to all host resources. This is also the recommended method to connect to the local hypervisor.

```bash
sudo virsh uri
```

qemu:///system

So, if you want to connect to a system instance as a regular user with full access to all host resources, do the following.

Add the regular user to the libvirt group.

### Add User to Groups

Add your current user to the necessary groups.

```bash
sudo usermod -aG libvirt,kvm,input,disk "$(id -un)"
```

- **Why:**

- `libvirt`: Grants permission to manage VMs (based on the config change above).

- `kvm`: Grants access to the `/dev/kvm` device (hardware acceleration).

- `input`: (Optional but recommended) Allows input capture for advanced setups.

- `disk`: (Optional) Helpful if managing raw disk images directly.


> [!TIP] Restart Session
> 
> You usually need to log out and log back in (or restart) for these group changes to take effect.
Define the environment variable LIBVIRT_DEFAULT_URI in the local .zshrc file of the user.

---
---

# SKIP THIS PART (IT'S ALREADY SET IN THE UWSM FILE IF YOU USE THE DUSK CONFIG FILES. )
```bash
echo "export LIBVIRT_DEFAULT_URI='qemu:///system'" >> ~/.zshrc
source ~/.zshrc
```

Check again as a regular user to see which instance you are connected to.

```bash
virsh uri
```

this is to connect to the user session, which shoudnt be done for gpu passthrough. 
```bash
virt-manager --connect qemu:///session
```

connect to the root/ system kvm recommanded.!!
```bash
virt-manager --connect qemu:///system
```


You can now use the virsh command-line tool and the Virtual Machine Manager (virt-manager) without sudo