First check if the kernal modules are already loaded or not 

### ✅ Verifying the Module

- To confirm that the KVM kernel modules have been loaded successfully, you can use the `lsmod` command, which lists all active kernel modules, and pipe it to `grep` to search specifically for "kvm".

**Command:**
```bash
lsmod | grep kvm
```

**Expected Output:**

If the modules are loaded correctly, the output will look similar to this, confirming that both the core `kvm` module and the processor-specific module (`kvm_intel` in this case) are active.

```ini
kvm_intel             434176  0
kvm                  1388544  1 kvm_intel
irqbypass              12288  1 kvm
```

If they are not loaded, load them with the following command. 

## Load the KVM kernel module:

For Intel CPUs:

```bash
sudo modprobe kvm_intel
```


To auto-load on boot, append to /etc/modules-load.d/kvm.conf:

```bash
echo kvm_intel | sudo tee /etc/modules-load.d/kvm.conf
```

then reboot 

```bash
systemctl reboot
```
