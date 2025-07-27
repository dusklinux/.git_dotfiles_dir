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
