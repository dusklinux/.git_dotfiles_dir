
To maximize the effectiveness of ZRAM, it's essential to tune specific kernel VM (Virtual Memory) parameters. These adjustments will encourage the system to aggressively use the fast ZRAM swap, improving responsiveness under memory pressure.

This guide will walk you through creating a dedicated configuration file, applying the settings, and verifying that they are active.

---

### 1. Create the Kernel Parameter Configuration File

First, create a new `sysctl` configuration file. Placing it in `/etc/sysctl.d/` ensures it's automatically loaded on boot. The `99-` prefix ensures it's loaded last, overriding any default values.

```bash
sudo nvim /etc/sysctl.d/99-vm-zram-parameters.conf
```

### 2. Add Optimized Parameters

Insert the following content into the file you just created.

```ini
vm.swappiness = 180
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
vm.page-cluster = 0
```

> [!NOTE] Parameter Explanations
> These settings are specifically chosen to optimize for a RAM-based swap device like ZRAM.

| Parameter | Value | Description |
| :--- | :--- | :--- |
| `vm.swappiness` | `180` | Aggressively swaps idle application data to the fast ZRAM device. Values can range from 0-200. |
| `vm.watermark_boost_factor` | `0` | Disables the memory reclamation boost, which can be counterproductive with ZRAM's performance characteristics. |
| `vm.watermark_scale_factor` | `125` | Increases the memory buffer size before the `kswapd` process begins swapping, providing more headroom. |
| `vm.page-cluster` | `0` | Swaps one page at a time instead of in clusters, which is more efficient for fast, non-rotational devices like RAM. |

### 3. Apply and Verify the Changes

You must apply the new settings and then verify that the kernel is using them.

#### Apply Changes

This command loads all settings from `/etc/sysctl.d/` and applies them to the live kernel, avoiding the need for a reboot.

```bash
sudo sysctl --system
```

#### Verify Settings

> [!TIP] Always Verify
> A fastidious administrator never trusts, but always verifies. Use the following commands to inspect the live kernel values and confirm your changes were applied correctly. This is also useful for comparing the system's state before and after the changes.

You can verify all parameters with a single command:

```bash
sysctl vm.swappiness vm.watermark_scale_factor vm.page-cluster vm.watermark_boost_factor
```

Alternatively, you can inspect each parameter individually:

```bash
sysctl vm.swappiness
sysctl vm.watermark_boost_factor
sysctl vm.watermark_scale_factor
sysctl vm.page-cluster
```

If the output matches the values you set in the configuration file, your system is now optimized for ZRAM.

