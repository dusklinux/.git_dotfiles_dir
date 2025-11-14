> [!ATTENTION] It is highly recommended to use zram1 as block stroage instead of ramdisk.
> zram has the ability to be formated as any file system and also has zstd compression support. 
> Zefer to [[ZRAM Setup]] 


This step is optional and outlines how to create a ramdisk, which uses a portion of your system's RAM as a temporary, high-speed storage volume.

> [!TIP] Why use a ramdisk?
> A ramdisk (`tmpfs`) is ideal for temporary data like browser caches, build directories, or other transient files. It offers significant speed benefits and can help reduce wear on SSDs. Be aware that all data stored on a ramdisk is volatile and will be erased upon reboot or shutdown.

### 1. Create the Mount Point

First, create the directory where the ramdisk will be mounted.

```bash
mkdir /mnt/ramdisk
```

### 2. Find Your User and Group ID

To ensure your user account has the correct permissions to write to the ramdisk, you must identify its User ID (UID) and Group ID (GID).
> [!NOTE] If you're doing this before creating an account during arch install.
>  You cannot look for your uid/gid right now.
>  No user account exists yet, but once it's created, you can verify that it's uid and gid are 1000.  
>  For now you can proceed with setting them as 1000 for each (it's safe). 
>  For the first user created on a system, these values are typically `1000`, but you should always verify.
  
```bash
id
```


### 3. Edit `fstab` for Automatic Mounting

To make the ramdisk mount automatically at boot, you need to add an entry to the `/etc/fstab` file.

Open the file in a text editor:

```bash
nvim /etc/fstab
```

Add the following line to the end of the file. Be sure to **replace `1000`** with the actual `uid` and `gid` you found in the previous step. You can also adjust the `size` parameter to allocate more or less RAM.

```fstab
#ramdisk
tmpfs /mnt/ramdisk tmpfs rw,noatime,exec,size=6G,uid=1000,gid=1000,mode=0755,comment=x-gvfs-show 0 0
```

> [!WARNING] Filesystem Options
> The `tmpfs` filesystem does not support BTRFS-specific options like `compress=zstd:3`. Do not add such flags to the `tmpfs` entry. These options are only for BTRFS partitions.

### See Also

-   [[fstab reference]]
