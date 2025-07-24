Windows boot repair UEFI

Make sure to not leave anything on the disk as unallocated space where you don’t want for it to create the partition EFI drive or the other partition.. temporary format did the large unallocated partition as an F2FS format or something. and then when all of this is done and dusted after boot has been repaid,.

Before fixing the boot make sure to only list the amount you want for efi and stuff  as allocated, small unallocated 500 MB partition as unallocated and make sure it’s position is where you wanted to be so through gparted

diskpart
    Select the disk
list disk
select disk x



 (Optional) Select the partition on it if it’s formatted as something and not unallocated, like if you’ve formatted it as something  eg, ext4 with 500mb. Select that partition
list volume
select partition x
delete partition override

From here on, continue in both cases (unallocated or a disk formatted as something. 
  This can be anywhere from 260 to 500 mb I set as 350
create partition efi size=350
format quick fs=fat32 label="System"
assign letter=S
create partition msr size=128
  Verify the created partitions (both) system as 350 and reserved as 128 (system and reserved are listed as such)
list partition
Now check the drive letter for the main windows partition eg C:\ (it’s the NTFS DRIVE)
list volume
  Now exit from diskpart
exit
  This is important (c is your windows main and s is the drive letter you assigned earlier) the small “/s” means specify.
bcdboot C:\Windows /s S: /f UEFI
