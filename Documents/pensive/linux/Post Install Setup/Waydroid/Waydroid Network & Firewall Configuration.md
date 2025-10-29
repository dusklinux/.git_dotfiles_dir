## Network & Firewall Configuration

If Waydroid cannot access the internet, you may need to add a firewall rule to permit traffic through its virtual network interface.

#### For `firewalld` Users

The following commands will add the `waydroid0` interface to your trusted zone, allowing it to bypass restrictions.

```bash
# Add the firewall rule permanently
sudo firewall-cmd --zone=trusted --add-interface=waydroid0 --permanent

# Reload the firewall to apply the new rule
sudo firewall-cmd --reload
```


### if the above doesn't work. do the following

Waydriod Network: 
check if waydroid0 is up and has an ip.

```bash
ip addr show waydroid0
```

check if packet forwarding is active (should be 1)

```bash
sysctl net.ipv4.ip_forward
```

if it's 0, enable it with 

```bash
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-waydroid.conf
sudo sysctl -p /etc/sysctl.d/99-waydroid.conf
```

Add NAT (masquerading) rules

```bash
sudo firewall-cmd --zone=trusted --add-masquerade --permanent
sudo firewall-cmd --reload
```

Then forward traffic between waydroid0 and your internet device (replace wlan0 with your actual interface):

```bash
sudo firewall-cmd --zone=trusted --add-forward --permanent
sudo firewall-cmd --direct --add-rule ipv4 nat POSTROUTING 0 -o wlan0 -j MASQUERADE
sudo firewall-cmd --reload
```

```bash
sudo waydroid session stop && sudo waydroid container stop
```