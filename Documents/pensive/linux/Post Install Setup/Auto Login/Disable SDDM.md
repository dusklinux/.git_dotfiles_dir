> [!IMPORTANT]
> This method replaces a traditional display manager like SDDM or GDM. If you have one installed, you must disable it first.

---

## 1. Disable Your Display Manager

If you have a display manager like SDDM installed and enabled, you must disable its service to prevent conflicts with the TTY auto-login method.

> [!WARNING] Do Not Use the `--now` Flag
> Disabling the service with `sudo systemctl disable --now sddm.service` will immediately stop the service and crash your current graphical session. Run the command without the flag.

```bash
sudo systemctl disable sddm.service
```

---