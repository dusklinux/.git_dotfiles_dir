
The Virtual Machine Manager wizard lets you quickly create a guest virtual machine with the default settings. Once that's done, you can make additional changes to the settings to ensure that the Windows 11 virtual machine runs smoothly.

STEP 1: Choose how you would like to install the operating system.

As you are installing Windows 11 from an ISO image, choose the first option. `Local install media (ISO image or CDROM)`

---

STEP 2: Choose ISO installation media.

Provide the location of the Windows 11 ISO installer image. `Browser Local` to navigate to the directory containing the iso and select the iso. 

Sometimes it wont autodected the type of OS you're ISO contains in which case uncheck `Automatically detect from the installation media / source` and then type in the operating system and pick one of the suggested options. Dont' type the type of os Manually, select from one of the listed ones. 
Then click the Forward button.

---

STEP 3: Choose Memory and CPU settings.

Set the amount of host memory and virtual CPUs that will be assigned to the guest virtual machine. You can set this based on your RAM and CPU availability. Click the Forward button to continue.

---

STEP 4: Enable storage for this virtual machine.

choose `Select or create custom storage`
and then `Manage`

> [!tip] it doesn't let you pick a custom volume in a straight forward way so follow each steps to the T
> we'll first create a volume that is 0 mb in size, this is just so it lets you see the target external directory's Location/path, otherwise it doesn't let you select the external drive with an empty directory.  **Sometimes the 0 mb .qcow2 is not created but it still lists the target location of the external drive, which is great** 

> [!tip] important to know
> `Pool` means the entire directory in which there are files. 
> `Volume` means the file

Create a New Pool by clicking the `+` icon at the bottom left which, when hovered on, will say `Add Pool` 

Set the name as `pool_test` or something
and the `Type` as `dir: Filesystem Directory`
Then `Target Path:` to where you want to create and save the virtual file image. (ive created mine on an external hard disk,  WD)
and then click `Finish`

now it'll take you back to the previous window, On the left hand side of the window, it'll show you the newly created file-system , click it and select the Volume 

(notice it says 0 MBs, this will be deleted after the actual volume is created, **Sometimes this is not created at all, which is great cuz you don't have to delete it but make sure you're Location is listed as where you want to place the virtual machine image** )

Then click the other `+` icon at the top, right next to `Volumes ` 

![[Pasted image 20250726180159.png]]

select the format as `qcow` The disk image that is created will be of the type QCOW2, which is a copy-on-write format. The QCOW2's initial file size will be smaller, and it will only grow as more data is added. To install Windows 11, you need to have a disk space of 64 GiB or greater. 

*Dont* check the `Allocate entire volume now` or all the storage will be allocated right now. 
and then click `Finish`

this might take quite a while to finish
`Choose Volume` this will take you back to the wizard windows, and then click `Forward` 


---

STEP 5: Set the name of the virtual machine.

This is the final configuration screen of the Virtual Machine Creation Wizard. Give the guest virtual machine a name. I'll set it to 'Windows-11', but you can change it to anything you want.

Also, ensure that the `Customize configuration before install` checkbox is selected. Click the Finish button to finish the wizard and proceed to the advanced options.

---

