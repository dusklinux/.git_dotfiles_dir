VirtIO drivers are para-virtualized drivers for KVM guests. Microsoft, unfortunately, does not provide these drivers. When installing a Microsoft Windows virtual machine, you must install certain VirtIO drivers.

As a result, you must mount the virtio-win.iso image file, which contains the VirtIO drivers for Windows. This requires the addition of a second CDROM.

Click the Add Hardware button, then under `Storage` select `Device Type:`as  `CDROM device` Then under `Select or create custom storage` click `Manage` and select the `virtio-win.iso` image file. , it's usually already listed under the `default` pool. 

if for some reason you can't find the virtio-win.iso , figure out where it was downloaded by paru and point to that directory. 

and then select the volume and `finish`

the second cd rom will now show up. 

**The virtio-win.iso will have already been downloaded after following the KVM setup instructions**

`Apply`