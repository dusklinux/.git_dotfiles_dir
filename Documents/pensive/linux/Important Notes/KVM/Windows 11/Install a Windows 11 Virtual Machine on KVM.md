Now that you have finished configuring Windows 11 virtual hardware and have clicked the `Begin Installation` button at the top left, the Windows 11 installation starts.

once the installation begins You must then select the disk on which Windows 11 will be installed. However, as you probably see, the installer was unable to find any drives.

This is because you selected the VirtIO disk bus when configuring Windows 11 virtual hardware. VirtIO devices are not natively recognized by Windows, so you must manually install the drivers.

To install the VirtIO disk driver, click `Load driver`, then `Browse`, expand the `CD Drive (E:)`, expand `Viostor`, expand `w11`, select `amd64`, and click `OK`.

and then install the `Red Hat virtio ....` driver

> [!danger] Don't proceed with the installation just yet. You still need to install the VirtIO network driver.

Repeat the procedure for the network device as well. Click `**Load driver**` again, then `**Browse**`, expand the `**CD Drive (E:)**`, expand `**NetKVM**`, expand `**w11**`, select `**amd64**`, and click `**OK**`.
And then install it. 

After installing the VirtIO network device driver, click the Next button to proceed with the installation.

---

After installing windows and booting into the os for the first time you must install VirtIO Windows Guest Tools. This package includes some optional drivers and services that will boost SPICE performance and integration. This includes the QXL video driver as well as the SPICE guest agent for copy and paste, automatic resolution switching, and other features.

So launch **Windows Explorer**, navigate to the `**CD Drive (E:)**`, and double-click the `**virtio-win-guest-tools**` package to install it.

> [!note] Dont install the 64 or the 86 file instead install `virtio-win-guest-tools`

After installing the guest tools, on the Windows-11 KVM window, at the top of the virt viewer,  click `View`, `Scale Display`, and check the `Auto resize VM with window` option. This will enable the Windows 11 guest window to automatically resize as you scale it.


The Windows 11 operating system installation is now complete. Shut down the Windows 11 virtual machine.

---

Now that you've installed guest tools, you don't need the second CDROM drive. Click the lightbulb icon at the top, in between the computer display icon and the start icon, to access the hardware details. Unmount the virtio-win.iso image and then remove the second CDROM drive.
![[Pasted image 20250726223648.png]]
Unmount the ISO image of the Windows 11 installer from the first CDROM drive as well.

