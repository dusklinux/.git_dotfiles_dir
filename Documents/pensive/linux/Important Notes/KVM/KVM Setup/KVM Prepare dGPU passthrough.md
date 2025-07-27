Identify your NVIDIA GPU’s PCI IDs e.g. 
```bash
lspci -nn | grep NVIDIA
```

 Then bind it to VFIO so Linux won’t use it. You can do this by adding a module option or kernel parameter. For example, create /etc/modprobe.d/vfio.conf but (Use your GPU’s vendor:device IDs.)
 
> [!warning] use your gpu's vender: device ID , dont use the one in example command

Open the grub file and add the kernel parameters to it. 

```bash
sudo nvim /etc/default/grub
```

find this line `GRUB_CMDLINE_LINUX_DEFAULT=""` and add *YOUR* unique id's to it, make sure to add it at after any other existing kernel parameters each parameter is separated by a single space.  

```bash
vfio-pci.ids=10de:25a0,10de:2291
```

Regenerate grub 
```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

could reboot now if you want

```bash
systemctl reboot
```

### Now create and add options to the initramfs file conf file to start the vfio early 

```bash
sudo nvim /etc/modprobe.d/vfio.conf
```

```bash
options vfio-pci ids=10de:25a0,10de:2291
softdep nvidia pre: vfio-pci
```

Regenerate mkinitcpio

```bash
sudo mkinitcpio -P
```

Confirm the driver in use, this command should show Kernel driver in use, before restarting it should be there respective drivers eg NVIDIA graphics card and the NVidia audio controller should be `nvidia` and `snd_hda_intel`

```bash
lspci -nnk
```

> [!NOTE]- e.g Command output before reboot
> 0000:01:00.0 VGA compatible controller [0300]: NVIDIA Corporation GA107M [GeForce RTX 3050 Ti Mobile] [10de:25a0] (rev a1)
> 	Subsystem: ASUSTeK Computer Inc. Device [1043:1ccc]
> 	Kernel driver in use: nvidia
> 	Kernel modules: nouveau, nvidia_drm, nvidia
> 0000:01:00.1 Audio device [0403]: NVIDIA Corporation GA107 High Definition Audio Controller [10de:2291] (rev a1)
> 	Subsystem: ASUSTeK Computer Inc. Device [1043:1ccc]
> 	Kernel driver in use: snd_hda_intel
> 	Kernel modules: snd_hda_intel


Reboot:
```bash
systemctl reboot
```


After rebooting Confirm vfio-pci driver in use, it shoudl now be `vfio-pci` 

```bash
lspci -nnk
```


> [!NOTE]- e.g Command output after reboot
> 0000:01:00.0 VGA compatible controller [0300]: NVIDIA Corporation GA107M [GeForce RTX 3050 Ti Mobile] [10de:25a0] (rev a1)
> 	Subsystem: ASUSTeK Computer Inc. Device [1043:1ccc]
> 	Kernel driver in use: vfio-pci
> 	Kernel modules: nouveau, nvidia_drm, nvidia
> 0000:01:00.1 Audio device [0403]: NVIDIA Corporation GA107 High Definition Audio Controller [10de:2291] (rev a1)
> 	Subsystem: ASUSTeK Computer Inc. Device [1043:1ccc]
> 	Kernel driver in use: vfio-pci
> 	Kernel modules: snd_hda_intel