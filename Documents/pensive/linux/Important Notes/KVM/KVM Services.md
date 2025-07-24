| Service    | Description                                                                                                |
| ---------- | ---------------------------------------------------------------------------------------------------------- |
| `libvirtd` | The main libvirt daemon. Manages VMs, networks, storage pools, and interacts with QEMU/KVM on your behalf. |
| `virtlogd` | Handles logging of VM output for QEMU instances, separates log handling from `libvirtd` for robustness.    |


```bash
sudo systemctl enable --now libvirtd.service virtlogd.service
```
