custom win 10 iso wont be auto detected as windows 10, uncheck 
`Automatically detect from the installation media / source` 
and then manually select windows 10

Ram usage. 
for windows 10 3 GB will suffice for light weight usage. but recommanded is 5 or over. 

cores: could just be 1 depending on how many you can spare. 

for storage: Select the option. 
`Select or create custom storage`
and then 
`Manage`
give it 60 GB if you can afford to otherwise 40GB or possibly less will also do. 

highly recommanded to chose your desired location for where the vm's qcow2 file is stored.
> [!tip] important to know
> `Pool` means the entire directory in which there are files. 
> `Volume` means the file

Frist pick the directory in which the massive vm will will be stored, label the directory `Pool1` or something in the virt manager, create the vm file by adding first creating the file. 

Create a New Pool by clicking the `+` icon at the bottom left which, when hovered on, will say `Add Pool` 
Set the name as `pool_test` or something
and the `Type` as `dir: Filesystem Directory`
Then `Target Path:` to where you want to create and save the virtual file image. (ive created mine on an external hard disk,  WD)
and then click `Finish`
select the format as `qcow2` The disk image that is created will be of the type QCOW2, which is a copy-on-write format. The QCOW2's initial file size will be smaller, and it will only grow as more data is added. To install Windows 11, you need to have a disk space of 64 GiB or greater. 

*Dont* check the `Allocate entire volume now` or all the storage will be allocated right now. 
and then click `Finish`

this might take quite a while to finish
`Choose Volume` this will take you back to the wizard windows, and then click `Forward` 
![[Pasted image 20250726180159.png]]


STEP 5: Set the name of the virtual machine.

This is the final configuration screen of the Virtual Machine Creation Wizard. Give the guest virtual machine a name. I'll set it to 'win10' - the default name, but you can change it to anything you want.


Also, ensure that the `Customize configuration before install` checkbox is selected. Click the Finish button to finish the wizard and proceed to the advanced options.

(we'll configure network on the next window)


