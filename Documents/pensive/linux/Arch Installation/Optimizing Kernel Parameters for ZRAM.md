
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
# --- ZRAM & SWAP BEHAVIOR ---
# Aggressively swap anonymous memory to ZRAM to free up space for page cache
vm.swappiness = 190
# ZRAM is non-rotational; disable read-ahead
vm.page-cluster = 0

# --- FILESYSTEM CACHE (The "Snappy" Factor) ---
# Retain dentry and inode caches strictly
vm.vfs_cache_pressure = 10
# Allow dirty data to stay in RAM for a bit, but flush in smooth streams
vm.dirty_bytes = 1073741824
vm.dirty_background_bytes = 268435456

# --- MEMORY ALLOCATION & COMPACTION ---
# Increase the reserve to prevent Direct Reclaim stutters
vm.watermark_scale_factor = 300
# Disable the boost factor as we have a static high scale factor
vm.watermark_boost_factor = 0
# Aggressively defragment memory for HugePages
vm.compaction_proactiveness = 50
# Reserve space for atomic operations (Network/DMA)
vm.min_free_kbytes = 131072

# --- APPLICATION COMPATIBILITY ---
# Prevent "map allocation failed" errors in heavy games/apps
vm.max_map_count = 2147483642
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
sysctl vm.swappiness vm.watermark_scale_factor vm.page-cluster vm.watermark_boost_factor vm.max_map_count vm.min_free_kbytes vm.compaction_proactiveness vm.dirty_background_bytes vm.dirty_bytes vm.vfs_cache_pressure
```

If the output matches the values you set in the configuration file, your system is now optimized for ZRAM.

