
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

This step should already be done. 

```bash
sudo usermod -aG libvirt $USER
```

Define the environment variable LIBVIRT_DEFAULT_URI in the local .zshrc file of the user.

```bash
echo "export LIBVIRT_DEFAULT_URI='qemu:///system'" >> ~/.zshrc
source ~/.zshrc
```

Check again as a regular user to see which instance you are connected to.

```bash
virsh uri
```

qemu:///system

You can now use the virsh command-line tool and the Virtual Machine Manager (virt-manager) without sudo