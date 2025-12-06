
```bash
sudo nvim /etc/sysctl.d/99-vm-zram-parameters.conf
```

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