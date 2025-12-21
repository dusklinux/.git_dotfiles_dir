
```bash
dbus-send --session --print-reply --dest=org.freedesktop.impl.portal.PermissionStore \
    /org/freedesktop/impl/portal/PermissionStore \
    org.freedesktop.impl.portal.PermissionStore.DeletePermission \
    string:'devices' string:'camera' string:''
```