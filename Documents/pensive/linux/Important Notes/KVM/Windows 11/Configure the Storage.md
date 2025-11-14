From the left panel, select SATA Disk 1.

Change the disk bus from SATA to VirtIO. VirtIO is preferred over other emulated storage controllers as it is specifically designed and optimized for virtualization.

Under `Advanced Options`

Set the `cache` mode to `none`. In this mode, the host page cache is bypassed, and I/O occurs directly between the hypervisor user space buffers and the storage device. In terms of performance, it is equivalent to direct disk access on your host.

Set the `discard` mode to `unmap`. When you delete files in the guest virtual machine, the changes are reflected immediately in the guest file system. The qcow2 disk image associated with the VM on the host, however, does not shrink to reflect the newly freed space. When you set the discard mode to unmap, the qcow2 disk image will automatically shrink to reflect the newly freed space.

and then Apply changes
`Apply`