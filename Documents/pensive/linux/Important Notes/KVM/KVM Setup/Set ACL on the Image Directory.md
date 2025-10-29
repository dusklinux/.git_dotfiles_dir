Set ACL on the Images Directory

By default, virtual machine disk images are stored in the /var/lib/libvirt/images directory. Only the root user has access to this directory.

```bash
ls /var/lib/libvirt/images/
```

ls: cannot open directory '/var/lib/libvirt/images/': Permission denied

As a regular user, you might want access to this directory without having to type sudo every time. So, setting the ACL for this directory is the best way to access it without changing the default permissions.

First, recursively remove any existing ACL permissions on the directory.

```bash
sudo setfacl -R -b /var/lib/libvirt/images
```

Grant regular user permission to the directory recursively.

```bash
sudo setfacl -R -m u:$(id -un):rwX /var/lib/libvirt/images
```

The capital 'X' above indicates that 'execute' should only be applied to child folders and not child files.

All existing directories and files (if any) in /var/lib/libvirt/images/ now have permissions. However, any new directories and files created within this directory will not have any special permissions. To get around this, we need to enable 'default' special permissions. The 'default acls' can only be applied to directories and not to files.

```bash
sudo setfacl -m d:u:$(id -un):rwx /var/lib/libvirt/images
```

Now review your new ACL permissions on the directory.

```bash
getfacl /var/lib/libvirt/images
```

>getfacl: Removing leading '/' from absolute path names
>file: var/lib/libvirt/images
>owner: root
>group: root
>user::rwx
>user:madhu:rwx
>group::--x
>mask::rwx
>other::--x
>default:user::rwx
>default:user:madhu:rwx
>default:group::--x
>default:mask::rwx
>default:other::--x

Try accessing the /var/lib/libvirt/images directory again as a regular user.

```bash
touch /var/lib/libvirt/images/test_file
```

```bash
ls -l /var/lib/libvirt/images/
```

>total 0
>-rw-rw----+ 1 madhu madhu 0 Feb 12 21:34 test_file

You now have full access to the /var/lib/libvirt/images directory