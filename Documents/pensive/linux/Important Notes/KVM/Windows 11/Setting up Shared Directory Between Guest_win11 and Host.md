a new file system called Virtiofs was created. Virtiofs is a shared file system that allows virtual machines to access the host's directory tree. Its purpose is to emulate the semantics and performance of the local filesystem.

To demonstrate this, I'll share the zram1 directory of my host system with the Windows 11 guest virtual machine.

Before you begin, ensure that you have VirtIO Windows guest tools installed in your Windows 11 guest virtual machine. which should have been done by following the previous steps. 

## Set Up a Shared Directory on the Host

Launch the Virtual Machine Manager application.
Select the Windows guest on which you want to mount the shared directory of the host. Then, click the `**Open**` button. In the new window that appears, click the `lightbulb icon` in the toolbar to show virtual hardware details.
![[Pasted image 20250727150813.png]]

You must enable shared memory backing. Memory backing enables virtual memory pages to be backed by host pages.

On the left panel, select `Memory`, and on the right panel, check the `Enable shared memory` checkbox. Then press the `Apply` button.


Next, on the left bottom, click the `Add Hardware button`. In the new window that appears, select the `Filesystem` option from the left panel.

In the right panel, set the driver to `virtiofs` (might already be set as such). Set the `Source path` to the directory on the host that you want to share with the Windows 11 guest virtual machine. I’ll be sharing my zram1 directory, so I’ll set the path to `/mnt/zram1` by typing it out. Then, in the `Target path`, enter any arbitrary string. This string will be used to identify the shared directory that will be mounted within the Windows 11 guest. I’ll set it to `host zram1`, but you can change it to whatever you want. Complete the process by hitting the `Finish` button.

Finally, run the Windows-11 guest virtual machine by clicking the `computer monitor icon` and then the `play icon` in the toolbar.

Install Windows File System Proxy

WinFsp (Windows File System Proxy) is system software that provides runtime and development support for custom file systems on Windows computers. In this sense, it is similar to FUSE (Filesystem in Userspace), which provides the same functionality on UNIX-like computers.

But, before you install WinFsp, make sure your Windows 11 is up to date. either by checking updates or by using the `Windows Update Mini tool` if you're using a debloated version of windows. 

After you have updated your drivers or whatever,  download and install the most recent stable version of the WinFsp MSI package.
github link

```bash
https://github.com/winfsp/winfsp/releases
```

Once the WinFsp package is installed, reboot your Windows 11 guest virtual machine.
Mount the Shared Directory on the Windows Guest Virtual Machine

Now that you have installed the WinFsp package, you have to enable the `VirtIO-FS Service` in the Windows 11 guest virtual machine in order to mount the shared directory.

To enable `VirtIO-FS Service`, type `services` into the search box and press `Enter` to open the Services window.

In the Services window, look for `VirtIO-FS Service`. Right-click it and select Properties. Then, enable the `VirtIO-FS Service`.

Then launch Windows Explorer, and you should see your shared directory mounted.

The file sharing between the KVM host and Windows guest using Virtiofs is now complete.

