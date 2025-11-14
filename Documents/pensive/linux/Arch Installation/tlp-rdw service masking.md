
### Masking `systemd-rfkill` for TLP

To allow TLP to properly manage Wi-Fi power-saving features, the `systemd-rfkill` services must be masked. This prevents conflicts and ensures TLP has exclusive control over your wireless hardware's power states.

Execute the following commands to mask the service and its corresponding socket:

```bash
sudo systemctl mask systemd-rfkill.service
sudo systemctl mask systemd-rfkill.socket
```

> [!NOTE] What does "masking" do?
> Masking a `systemd` service links it to `/dev/null`, which makes it impossible for the service to be started, either manually or as a dependency for another service. This is a stronger form of disabling and is recommended here to avoid any potential conflicts with TLP's Radio Device Wizard (RDW).

