> [!important] Disable ollama service if you have nvidia gpu 
> leaving the service running keeps the gpu awake and there's no way to see what's using it. and you'll never know. this is fine if you're primarly using the nvidia gpu, in which case the nvidia gpu will always be awake anyway. but if you have a laptop with integrated gpu that puts the dedicated gpu to sleep. this will prevent 3d state for the nvidia gpu
check if its' set to auto or not auto puts it in d3 state sleep, while on keeps it on all the time

swaync does this as well but it's not the service in that case, it's the ui of sway that is usually rendered on teh deicated gpu (it's been fixed by overriding the service in 
```bash
nvim ~/.config/systemd/user/swaync.service.d/gpu-fix.conf
```

```ini
[Service]
ExecStart=
ExecStart=/usr/bin/env VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/intel_icd.x86_64.json /usr/bin/swaync
```


---


```bash
cat /sys/bus/pci/devices/0000:01:00.0/power/control
```

current status of the sleep features
```bash
cat /proc/driver/nvidia/gpus/0000:01:00.0/power
```

curret sleep state status 
```bash
sudo cat /sys/bus/pci/devices/0000\:01\:00.0/power/runtime_status
```

to invoke deep sleep if ti's not doing so manually 

```bash
sudo tee /etc/modprobe.d/nvidia-pm.conf <<-EOF
options nvidia NVreg_DynamicPowerManagement=0x02
options nvidia NVreg_EnableGpuFirmware=0
options nvidia NVreg_EnableS0ixPowerManagement=1
EOF
```

```bash
sudo mkinitcpio -P
```

to check if the above modprobe.d /nvidia-pm.conf file was applied 

```bash
grep -R "NVreg_" /sys/module/nvidia*/parameters/
```

check all the nvidia drivers loaded
```bash
lsmod | grep -E 'nvidia|nv'
```

