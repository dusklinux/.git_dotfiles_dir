```bash
sudo pacman -S --needed qemu libvirt virt-manager virt-viewer git wget guestfs-tools p7zip make tesseract tesseract-data-eng cdrkit vim net-tools screen cdrtools
```

```bash
paru -S dmg2img uml_utilities
```

```bash
cd ~

git clone --depth 1 --recursive https://github.com/kholia/OSX-KVM.git

cd OSX-KVM
```

```bash
sudo modprobe kvm; echo 1 | sudo tee /sys/module/kvm/parameters/ignore_msrs
```

to make it perfminant 

check your cpu if unsure `lscpu`

```bash
sudo cp kvm.conf /etc/modprobe.d/kvm.conf
```

```bash
sudo usermod -aG kvm $(whoami)
sudo usermod -aG libvirt $(whoami)
sudo usermod -aG input $(whoami)
```

reboot
```bash
systemctl reboot
```

fetch macos installer

```bash
./fetch-macOS-v2.py
```

You can choose your desired macOS version here. After executing this step, you should have the BaseSystem.dmg file in the current folder.

> [!NOTE] IT MIGHT FREEZE FOR A WHILE AND THAT'S OKAY 
> ATTENTION: Let >= Big Sur setup sit at the Country Selection screen, and other similar places for a while if things are being slow. The initial macOS setup wizard will eventually succeed.

Convert the downloaded BaseSystem.dmg file into the BaseSystem.img file.

```bash
dmg2img -i BaseSystem.dmg BaseSystem.img
```

Create a virtual HDD image where macOS will be installed. If you change the name of the disk image from mac_hdd_ng.img to something else, the boot scripts will need to be updated to point to the new image name.

```bash
qemu-img create -f qcow2 mac_hdd_ng.img 256G
```

NOTE: Create this HDD image file on a fast SSD/NVMe disk for best results.

Now you are ready to install macOS 🚀

Installation

CLI method (primary). Just run the OpenCore-Boot.sh script to start the installation process.

```bash
./OpenCore-Boot.sh
```

Note: This same script works for all recent macOS versions.

Use the Disk Utility tool within the macOS installer to partition, and format the virtual disk attached to the macOS VM. Use APFS (the default) for modern macOS versions.

Go ahead, and install macOS 🙌

(OPTIONAL) Use this macOS VM disk with libvirt (virt-manager / virsh stuff).

Edit macOS-libvirt-Catalina.xml file and change the various file paths (search for CHANGEME strings in that file). The following command should do the trick usually.

```bash
sed "s/CHANGEME/$USER/g" macOS-libvirt-Catalina.xml > macOS.xml
virt-xml-validate macOS.xml
```

Create a VM by running the following command.

```bash
virsh --connect qemu:///system define macOS.xml
```

If needed, grant necessary permissions to libvirt-qemu user,

```bash
sudo setfacl -m u:libvirt-qemu:rx /home/$USER
sudo setfacl -R -m u:libvirt-qemu:rx /home/$USER/OSX-KVM
```

Launch virt-manager and start the macOS virtual machine.

[[setting up networking macos]]

change resolution: 
[[all notes macos]]

fix imessages
[[all notes macos]]