
Click the `Add Hardware` button at the bottom left to open the Add New Virtual Hardware window, and select `Channel` on the left pannel. . Then, from the drop-down list for `Name` select `org.qemu.guest_agent.0` and click `Finish`


The QEMU Guest Agent Channel establishes a private communication channel between the host physical machine and the guest virtual machine. This enables the host machine to issue commands to the guest operating system using libvirt. The guest operating system then responds to those commands asynchronously.

Add a QEMU guest agent channel to the Windows 11 guest virtual machine.








---

The following is Just for info

---

For example, after creating the Windows 11 guest virtual machine, you can shut it down from the host by issuing the following command:

```bash
sudo virsh shutdown Windows-11 --mode=agent
```

This shutdown method is more reliable than virsh shutdown --mode=acpi because it guarantees to shut down a cooperative guest in a clean state. If the agent is not present, libvirt must rely on injecting an ACPI shutdown event, which some guests ignore and thus do not shut down. You can also use the same syntax to reboot (virsh reboot).

Some of the commands you can try, among many others, are:

### Query the guest operating system's IP address via the guest agent.

```bash
sudo virsh domifaddr Windows-11 --source agent
```

### Show a list of mounted filesystems in the running guest.

```bash
sudo virsh domfsinfo Windows-11
```

### Instructs the guest to trim its filesystem.

```bash
sudo virsh domfstrim Windows-11
```

