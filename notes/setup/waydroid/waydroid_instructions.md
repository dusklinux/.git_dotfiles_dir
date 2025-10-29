
#WAYDROID#

	first downlaod venddor and system files of the foe either vanilla or gapps aka either linage 18 or lineage 20 then install waydroid

sudo dnf install waydroid
	DONT START YET
	extract and copy the system.img and vendor.img to /etc/waydroid-extra/images/ 
sudo mkdir /etc/waydroid-extra/
sudo mkdir /etc/waydroid-extra/images
	move or copy the files to the /etc.... directory with cp or mv
mv ~/Downloads/system.img /etc/waydroid-extra/images/
mv ~/Downloads/vendor.img /etc/waydroid-extra/images/
	since you moved the files manually, you need to add the -f option to initiializing waydoid
sudo waydroid init -f
sudo waydroid status
sudo waydroid session start
	hudini for translation layer for arm apps to work. there's a github. first root.
	
ROOT AND STUFF EXTRA
	copy the whole thing and paste in terinal if or do it one by one. 
git clone https://github.com/casualsnek/waydroid_script
cd waydroid_script
python3 -m venv venv
venv/bin/pip install -r requirements.txt
sudo venv/bin/python3 main.py


----------------------

once you've rooted your waydriod container, and you turn on zygisk, it requries a restart, but restarting the continer doesn't recognieze it as a complete resetart, since the container shares its kernal with the host, a full hosts's reboot is also required. maybe just do systemctl soft-reboot first to see if that works and if that doesn't  work, do a complete reboot. 

to share folders with waydroid
sudo mount --bind /mnt/ramdisk ~/.local/share/waydroid/data/media/0/Pictures 

	if you disconnect a session, you need to first unmount and then rebind but if you restaart your host pc, you need to rebind without having to unmount first. 

sudo umount -R ~/.local/share/waydroid/data/media/0/Pictures 

and then rebind

sudo mount --bind /mnt/ramdisk ~/.local/share/waydroid/data/media/0/Pictures 

	to fix your internt, make sure to make a firewall rule. (for firewalld)
sudo firewall-cmd --zone=trusted --add-interface=waydroid0 --permanent

	reload firewalld config
sudo firewall-cmd --reload

	files might not have read/right access inside waydroid, shared thorugh bind mount so give it requisite permissions. 

sudo chmod 777 -R /mnt/ramdisk
