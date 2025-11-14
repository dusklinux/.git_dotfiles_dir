ZRAM creates a compressed block device in your RAM that acts as a swap space. This is significantly faster than a traditional swap file or partition on a disk, improving system responsiveness, especially on systems with ample RAM.


> [!TIP] See manpage for zram-generator.conf for all available options. 
> ``` bash
> man zram-generator.conf
---

### 1. Create the ZRAM Configuration

The `zram-generator` service automatically configures ZRAM on boot based on the settings in `/etc/systemd/zram-generator.conf`.

Create the configuration file:
```bash
sudo nvim /etc/systemd/zram-generator.conf
```

Add the following content. This will create a ZRAM device named `zram0`.
> [!NOTE] Change the size that reflects your RAM capacity
>  The following is an example for devices with more than 2GB RAM 

> [!info]+ EXT2
> ```ini
> [zram0]
> zram-size = ram - 2000
> compression-algorithm = zstd
> 
> [zram1]
> zram-size = ram - 2000
> fs-type = ext2
> mount-point = /mnt/zram1
> compression-algorithm = zstd
> options = rw,nosuid,noatime,nodev,discard,X-mount.mode=1777
> ```



> [!TIP] Configuration Details
> 
> | Parameter | Description |
> |---|---|
> | `zram-size` | The uncompressed size of the swap device in megabytes. A common recommendation is 50% of your total RAM. there are multiple ways in which this can be set you could set a hard coded number eg, setting 8GB would be `zram-size = 8000` *note that the number should be in raw numbers eg 8000 for 8GB 4000 for 4GB etc* . the other way to set it is, dynamically. `ram` which means the entire RAM of the device or `ram / 2` (half the ram of the device) or `ram - 2000` which is all ram minux 2GB ..etc |
> | `compression-algorithm` | The algorithm used for compression. `zstd` is recommended for its excellent balance of speed and compression ratio. |
---
### 2. Activate and Verify ZRAM

The next steps depend on whether you are performing these actions from within the `chroot` environment during installation or on an already running system.

#### Scenario A: During Arch Installation (from `chroot`)

No further action is required. The configuration file you created is all that's needed. The `systemd-zram-setup@zram0.service` will automatically start and configure the device on your first boot into the new system.

---
#### Scenario B: On an Already Booted System

If you are configuring ZRAM on a running system, you must manually reload `systemd` and start the service to apply the changes immediately.

1.  **Reload the systemd manager configuration:**
```bash
sudo systemctl daemon-reload
```

2.  **Restart the ZRAM service:**
```bash
sudo systemctl restart systemd-zram-setup@zram0.service systemd-zram-setup@zram1.service
```

3.  **Verify the service status:**
   A successful activation will show the service as `active (exited)`.
```bash
sudo systemctl status systemd-zram-setup@zram0.service systemd-zram-setup@zram1.service
```

4.  **Start the ZRAM service if it's stopped:**
```bash
sudo systemctl start systemd-zram-setup@zram0.service systemd-zram-setup@zram1.service
```

5.  **Reload the systemd manager configuration:**
```bash
sudo systemctl daemon-reload
```

> [!CAUTION] Troubleshooting
> If the service fails to start, the most common cause is a syntax error in `/etc/systemd/zram-generator.conf`. Even so much as an extra space screws things up, so you're adviced to painstaingly rewrite the three short lines. 
> 
> 1.  Carefully check the configuration file for typos.
> 2.  Correct any errors and save the file.
> 3.  Repeat the `daemon-reload` and `restart` commands above.

--- 

#### Check which compression algorithm is being used. the one in brackets is the one being used. 

```bash
cat /sys/block/zram*/comp_algorithm
```