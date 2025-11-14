This is an optional step, if you want to change the location of the defualt image file location for the virtual operating system when installed to zram, proceed with this step, this is to mitigate needless write cycles on the ssd. 

this one command does it all. 

```bash
sudo rmdir /var/lib/libvirt/images
mkdir /mnt/zram1/os/
sudo ln -nfs /mnt/zram1/os/ /var/lib/libvirt/images 
```