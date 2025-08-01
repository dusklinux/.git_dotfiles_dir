check if its' set to auto or not auto puts it in d3 state sleep, while on keeps it on all the time
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

