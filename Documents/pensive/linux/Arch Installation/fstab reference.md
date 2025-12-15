# New

```ini

#XXXXXXXXXXXXXXXXXXXXXXXX--HARD DISKS BTRFS & NTFS--XXXXXXXXXXXXXXXXXXXXXXXXX

#External Machanacial Hard Disk - BTRFS (WD Passport)

#UUID=bb5a5a44-4b30-4db2-822f-ceab3171ee51	/mnt/fast	btrfs		defaults,discard=async,comment=x-gvfs-show,compress=zstd:3,noatime,space_cache=v2,nofail,noauto,autodefrag,subvol=/	0 0

#External Machanacial Hard Disk - NTFS (WD Passport)

#UUID=319E44F71F4E3E14	/mnt/slow	ntfs3	defaults,noatime,nofail,noauto,comment=x-gvfs-show,uid=1000,gid=1000,umask=002,windows_names   0 0


# WD ntfs passport fast
UUID=70EED6A1EED65F42	/mnt/fast	ntfs3	defaults,noatime,nofail,noauto,comment=x-gvfs-show,uid=1000,gid=1000,umask=002,windows_names   0 0


#External Machanacial Hard Disk - BTRFS (WD Passport) (no copy on write also disables compression zstd but improves speed of the drive)

UUID=5A921A119219F26D	/mnt/slow	ntfs3	defaults,noatime,nofail,noauto,comment=x-gvfs-show,uid=1000,gid=1000,umask=002,windows_names   0 0



#External Machanacial Hard Disk - BTRFS (OLD WD BOOK)

UUID=46798d3b-cda7-4031-818f-37a06abbeb37	/mnt/wdfast	btrfs		defaults,discard=async,comment=x-gvfs-show,compress=zstd:3,noatime,space_cache=v2,nofail,noauto,autodefrag,subvol=/	0 0


#External Machanacial Hard Disk - btrfs (OLD WD BOOK)

UUID=2765359f-232e-4165-bc69-ef402b50c74c	/mnt/wdslow	btrfs		defaults,discard=async,comment=x-gvfs-show,compress=zstd:3,noatime,space_cache=v2,nofail,noauto,autodefrag,subvol=/	0 0


#External Machanacial Hard Disk - NTFS (Enclosure)

UUID=5A428B8A428B6A19	/mnt/enclosure	ntfs3	defaults,noatime,nofail,noauto,comment=x-gvfs-show,uid=1000,gid=1000,umask=002,windows_names   0 0

#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX



#XXXXXXXXXXXXXXXXXXXXXXXX--SSDs BTRFS & NTFS--XXXXXXXXXXXXXXXXXXXXXXXXX

#SSD NTFS (Windows)

UUID=848A215E8A214E4C	/mnt/windows	ntfs3	defaults,noatime,uid=1000,gid=1000,umask=002,windows_names,noauto,nofail,comment=x-gvfs-show 0 0


#SSD BTRFS with Copy_on_Write Disabled which also disabled Compression (Browser)

UUID=1adeb61a-0605-4bbc-8178-bb81fe1fca09	/mnt/browser	btrfs		defaults,nodatacow,ssd,discard=async,comment=x-gvfs-show,noatime,space_cache=v2,nofail,noauto,subvol=/	0 0


#SSD NTFS (Media)

UUID=9C38076638073F30	/mnt/media	ntfs3	defaults,noatime,uid=1000,gid=1000,umask=002,windows_names,noauto,nofail,comment=x-gvfs-show 0 0


#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX


#Disk Swap

#UUID=6087d4bf-bd82-4c40-9197-3f5450b72241	none	swap	defaults 0 0

#Ramdisk (don't use this, use zram1 instead)

#tmpfs /mnt/ramdisk tmpfs rw,noatime,exec,size=2G,uid=1000,gid=1000,mode=0755,comment=x-gvfs-show 0 0
```



# OLD

```ini
# Static information about the filesystems.
# See fstab(5) for details.

# <file system> <dir> <type> <options> <dump> <pass>
# /dev/nvme0n1p5
UUID=3cddbe82-420a-44e7-b427-c21568c1e4f5	/         	btrfs     	rw,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2,subvol=/@	0 0

# /dev/nvme0n1p5
UUID=3cddbe82-420a-44e7-b427-c21568c1e4f5	/home     	btrfs     	rw,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2,subvol=/@home	0 0

# /dev/nvme0n1p4
UUID=F3C6-EFC7      	/boot     	vfat      	rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro	0 2






#XXXXXXXXXXXXXXXXXXXXXXXX--HARD DISKS BTRFS & NTFS--XXXXXXXXXXXXXXXXXXXXXXXXX

#External Machanacial Hard Disk - BTRFS (WD Passport)

UUID=bb5a5a44-4b30-4db2-822f-ceab3171ee51	/mnt/fast	btrfs		defaults,discard=async,comment=x-gvfs-show,compress=zstd:3,noatime,space_cache=v2,nofail,noauto,autodefrag,subvol=/	0 0




#External Machanacial Hard Disk - NTFS (WD Passport)

#UUID=319E44F71F4E3E14	/mnt/slow	ntfs3	defaults,noatime,nofail,noauto,comment=x-gvfs-show,uid=1000,gid=1000,umask=002,windows_names   0 0




#External Machanacial Hard Disk - BTRFS (WD Passport) (no copy on write also disables compression zstd but improves speed of the drive)

UUID=5A921A119219F26D	/mnt/slow	ntfs3	defaults,noatime,nofail,noauto,comment=x-gvfs-show,uid=1000,gid=1000,umask=002,windows_names   0 0




#External Machanacial Hard Disk - BTRFS (OLD WD BOOK)

UUID=bb5a5a44-4b30-4db2-822f-ceab3171ee51	/mnt/wdfast	btrfs		defaults,discard=async,comment=x-gvfs-show,compress=zstd:3,noatime,space_cache=v2,nofail,noauto,autodefrag,subvol=/	0 0




#External Machanacial Hard Disk - NTFS (OLD WD BOOK)

UUID=319E44F71F4E3E14	/mnt/wdslow	ntfs3	defaults,noatime,nofail,noauto,comment=x-gvfs-show,uid=1000,gid=1000,umask=002,windows_names   0 0




#External Machanacial Hard Disk - NTFS (Enclosure)

UUID=5A428B8A428B6A19	/mnt/enclosure	ntfs3	defaults,noatime,nofail,noauto,comment=x-gvfs-show,uid=1000,gid=1000,umask=002,windows_names   0 0

#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX



#XXXXXXXXXXXXXXXXXXXXXXXX--SSDs BTRFS & NTFS--XXXXXXXXXXXXXXXXXXXXXXXXX

#SSD NTFS (Windows)

UUID=848A215E8A214E4C	/mnt/windows	ntfs3	defaults,noatime,uid=1000,gid=1000,umask=002,windows_names,noauto,nofail,comment=x-gvfs-show 0 0



#SSD BTRFS with Copy_on_Write Disabled which also disabled Compression (Browser)

UUID=9cab0013-8640-483a-b3f0-4587cfedb694	/mnt/browser	btrfs		defaults,nodatacow,ssd,discard=async,comment=x-gvfs-show,noatime,space_cache=v2,nofail,noauto,subvol=/	0 0




#SSD NTFS (Media)

UUID=9C38076638073F30	/mnt/media	ntfs3	defaults,noatime,uid=1000,gid=1000,umask=002,windows_names,noauto,nofail,comment=x-gvfs-show 0 0


#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX




#Disk Swap

#UUID=6087d4bf-bd82-4c40-9197-3f5450b72241	none	swap	defaults 0 0




#Ramdisk (don't use this, use zram1 instead)

#tmpfs /mnt/ramdisk tmpfs rw,noatime,exec,size=2G,uid=1000,gid=1000,mode=0755,comment=x-gvfs-show 0 0

```