get the ids. 
```bash
lspci -nn | grep -E "NVIDIA"
```

kernal parambers with systemd boot or do grub. 
```bash
sudo nvim /boot/loader/entries/arch.conf
```

add these in teh same line as zswap.enabled=0
```ini
intel_iommu=on iommu=pt vfio-pci.ids=10de:25a0,10de:2291 module_blacklist=nvidia,nvidia_modeset,nvidia_uvm,nvidia_drm,nouveau
```

```bash
sudo nvim /etc/mkinitcpio.conf
```
if you have any more moduels other than btrfs, keep them there. dont remove. 
```ini
MODULES=(btrfs vfio_pci vfio vfio_iommu_type1)
```

eg, modconf and kms are what matter
```ini
HOOKS=(systemd autodetect microcode modconf kms keyboard sd-vconsole block filesystems)
```

blacklisting nvidia, also add your ids. 
```bash
sudo nvim /etc/modprobe.d/vfio.conf
```

```ini
options vfio-pci ids=10de:25a0,10de:2291
softdep nvidia pre: vfio-pci
blacklist nouveau
blacklist nvidia
blacklist nvidia_drm
blacklist nvidia_modeset
```

regerneage initramfs
```bash
sudo mkinitcpio -P 
```

check if vfio drivers are in use for nvidia. 

```bash
lspci -nnk -d 10de:25a0
```

```bash
lspci -k | grep -E "vfio-pci|NVIDIA"
```

```bash
sudo dmesg | grep -i vfio
```

attach vfio-pci driver to nvidia
```bash
sudo modprobe vfio-pci
```

===

---
---

```bash
sudo pacman --needed -S qemu-full libvirt virt-install virt-manager virt-viewer dnsmasq bridge-utils openbsd-netcat edk2-ovmf swtpm iptables-nft libosinfo
```
yes, remove and replace your iptables with iptables-nft if prompted. 

```bash
sudo systemctl enable --now libvirtd
```

```bash
sudo nvim /etc/libvirt/libvirtd.conf
```

```ini
unix_sock_group = "libvirt"
unix_sock_rw_perms = "0770"
```

```bash
sudo usermod -aG libvirt,kvm,input,disk "$(id -un)"
```

```bash
sudo virsh net-start default
sudo virsh net-autostart default
```



---
---

open virt manager. 

You should install it using the **System (Root) Connection** (`qemu:///system`), NOT the User session (`qemu:///session`).
"QEMU/KVM User session". This will cause major headaches for GPU passthrough. usually the user session isn't visible unless you entered a comand to make it visible. 

always choose bridge device for networking for easier sshing later. 
also always check,  Customize configuration before install

chipset q35, uefi. 


---
---

on windows, set password. 
check ip, 
set gpu gpraphics to nvidia in dislapay settings. 
downlaod and isntall looking glass host, extract and install. 
download and isntall 

enable memroy shared for ram in virt manager settings when windows is shutdown. 

install this on windows. 
```bash
https://github.com/VirtualDrivers/Virtual-Display-Driver
```

disable microsoft windows driver. 

```bash
paru -S looking-glass
```

```bash
sudo pacman -S freerdp
```

get ip and username from guest. 
```bash
xfreerdp3 /v:192.168.122.29 /u:dusk /dynamic-resolution
```

```bash
# Create the permission file
echo "f /dev/shm/looking-glass 0660 dusk kvm -" | sudo tee /etc/tmpfiles.d/10-looking-glass.conf

# Apply it immediately without rebooting
sudo systemd-tmpfiles --create /etc/tmpfiles.d/10-looking-glass.conf
```

Verify the file size is now correct (32MB): 1. _If it says ~33,554,432 bytes, you are ready to launch!)_ if not, follow the commands below. 
```bash
ls -l /dev/shm/looking-glass
```


```bash
sudo virsh list --all
```


```bash
sudo EDITOR=nvim virsh edit win11
```

- Scroll to the very bottom. Look for the `<memballoon>` section and the `</devices>` closing tag.
    
- Paste this block **between** them:

> [!NOTE]- context
> ```ini
> <memballoon model='virtio'>
>       <alias name='balloon0'/>
>       <address type='pci' domain='0x0000' bus='0x06' slot='0x00' function='0x0'/>
>     </memballoon>
> 
> <shmem name='looking-glass'>
>       <model type='ivshmem-plain'/>
>       <size unit='M'>32</size>
>     </shmem>
> </devices>
> ```

```ini
<shmem name='looking-glass'>
  <model type='ivshmem-plain'/>
  <size unit='M'>32</size>
</shmem>
```

```bash
sudo rm /dev/shm/looking-glass
```

```bash
sudo virsh destroy win11
```

```bash
sudo virsh start win11
```
Verify the file size is now correct (32MB): 1. _If it says ~33,554,432 bytes, you are ready to launch!)_
```bash
ls -l /dev/shm/looking-glass
```
this is what it shoudl show. 
`.rw-rw---- 34M dusk  9 Dec 16:26 󰡯 /dev/shm/looking-glass`

This is perfect. **`34M`** confirms the file is now exactly the right size (32MB + overhead). You have fixed the "Invalid argument" error.

There is just one tiny permissions hurdle left: the file is currently owned by `libvirt-qemu` (Read-only for you), but your user (`dusk`) needs to write to it to talk to the VM.

Step 1: Grant Yourself Access (Crucial)

Since QEMU just recreated the file, it reverted the ownership. Fix it for this session:

```bash
sudo chown dusk:kvm /dev/shm/looking-glass
sudo chmod 660 /dev/shm/looking-glass
```

```bash
looking-glass-client -f /dev/shm/looking-glass
```

change default  scroll lock key to right control key for looking glass
```bash
looking-glass-client -f /dev/shm/looking-glass -m KEY_RIGHTCTRL
```