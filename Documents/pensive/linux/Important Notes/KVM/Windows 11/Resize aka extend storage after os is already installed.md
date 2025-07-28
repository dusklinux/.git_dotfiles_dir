shutdown the vm completely and then run this in the terminal

make sure to specify the right path 

```bash
# Add (for example) 20 GiB:
sudo qemu-img resize /mnt/slow/documents/kvm/win10/win10.qcow2 +20G
```