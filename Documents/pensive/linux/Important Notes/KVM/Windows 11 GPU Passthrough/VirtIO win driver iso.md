## Crucial Step: VirtIO Drivers

Windows does not ship with drivers for KVM's paravirtualized hardware (VirtIO). Using generic IDE/SATA emulation is **slow**. For near-native performance, you must use VirtIO for the Disk and Network card, which requires downloading the drivers.

Option A: Install via AUR (easiest)

```bash
paru -S --needed virtio-win
```


>[!note]+ The downloaded virtio-win image is placed here. 
>```bash
>ls -lah /var/lib/libvirt/images
>```
> 
> or here
> ```bash
> ls -lah /usr/share/virtio/virtio-win.iso
> ```
> 


Option B: Manual Download

If you don't want the AUR package, download the stable ISO directly from Fedora (upstream for KVM drivers).
it'll downlaod the file at /mnt/zram1
```bash
cd /mnt/zram1/
wget https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso
```

> [!NOTE] this will later be explained in detail, just putting it here briefly 
> How to use this
> When creating your Windows VM in virt-manager:
> 
> 1. Set your Disk bus to **VirtIO**.
>     
> 2. Set your NIC (Network) device model to **virtio**.
>     
> 3. Attach the `virtio-win.iso` as a **second CD-ROM** drive.
>     
> 4. During Windows installation, when it can't find the disk, click "Load Driver" and browse the CD-ROM.
>     

