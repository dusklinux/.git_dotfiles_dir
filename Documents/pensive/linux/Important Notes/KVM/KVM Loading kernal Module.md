 
 Load the KVM kernel module:

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
