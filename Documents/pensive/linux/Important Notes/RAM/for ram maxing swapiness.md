
```bash
sudo nvim /etc/sysctl.d/99-vm-zram-parameters.conf
```

```ini
# 1. THE CACHE DIAL
# Default is 100. Lowering this tells the kernel:
# "Do NOT drop directory and inode caches."
# This makes listing files, searching, and opening apps feel instant.
# At 10, it effectively pins filesystem structure in RAM.
vm.vfs_cache_pressure = 10

# 2. WRITE CACHING (The Smoothness Factor)
# With 64GB, percentage-based ratios are dangerous (20% is 12GB of dirty data).
# If the system tries to flush 12GB at once, you will freeze.
# Instead, we set fixed byte limits.
# Allow 1GB of "dirty" data (writes) to sit in RAM before forcing a write.
vm.dirty_bytes = 1073741824 
# Start writing to disk in the background after just 256MB.
# This ensures a continuous, smooth stream of writes rather than a massive dump.
vm.dirty_background_bytes = 268435456

# 3. SWAP & ZRAM BEHAVIOR
# Your setting of 200 is theoretically correct for "Maximize Cache,"
# as it prefers swapping anonymous memory (program data) to ZRAM
# rather than dropping file caches.
vm.swappiness = 180  # Slight dial back to prevent CPU churn on ZRAM
vm.page-cluster = 0  # Keep this 0 for ZRAM (essential)

# 4. ALLOCATION SAFETY
# Your current settings are good, but let's bump the scale factor.
# This keeps a larger "free reserve" so the kernel never enters "Direct Reclaim"
# (which causes stutters). 3% of 64GB is plenty of safety buffer.
vm.watermark_scale_factor = 300
vm.watermark_boost_factor = 0
```