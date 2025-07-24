sudo usermod -aG libvirt,kvm $USER

You may need to log out and back in for group changes to take effect.

```bash
groups
```

```bash
groups $USER
```