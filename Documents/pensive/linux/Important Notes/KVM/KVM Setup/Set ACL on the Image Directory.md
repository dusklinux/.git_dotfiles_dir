# Setting ACLs on the Images Directory

> [!INFO] Context
> 
> By default, KVM/Libvirt stores virtual machine disk images in /var/lib/libvirt/images.
> 
> Strict security rules mean **only the root user** owns and can access this directory. As a regular user, this prevents you from creating or managing storage pools without using `sudo` for every single interaction.

## 1. Verify the Restriction

First, let's confirm the default behavior. If you try to list the contents of the storage directory as your regular user, 

or add SUDO to it and then run.
```
ls -lah /var/lib/libvirt/images/
```

if this is what you see, add sudo to it. and run again. 
> ls: cannot open directory '/var/lib/libvirt/images/': Permission denied

To fix this without breaking the system's default ownership (which should remain `root`), we will use **Access Control Lists (ACLs)**. This allows us to grant your specific user permission to the folder while leaving the rest of the security intact.

## 2. Clean Existing ACLs

Before applying new rules, it is best practice to strip away any specific Access Control Lists that might already exist to ensure we start with a clean slate.

- `-R`: Recursive (applies to the folder and everything inside it).
    
- `-b`: Remove all extended ACL entries.
    

```bash
sudo setfacl -R -b /var/lib/libvirt/images
```

## 3. Grant User Permissions (Current Files)

Now we apply the permissions for your specific user. We will use `$(id -un)` to automatically insert your current username, so you don't have to type it manually.

```bash
sudo setfacl -R -m u:$(id -un):rwX /var/lib/libvirt/images
```

> [!NOTE] Understanding the Capital 'X'
> 
> You will notice we used rwX (capital X) instead of rwx (lowercase x).
> 
> - **Lowercase `x`:** Gives execute permission to files and directories unconditionally. This would make every disk image "executable," which is messy.
>     
> - **Uppercase `X`:** Smart execute. It only gives execute permission to **directories** (so you can enter them) and files that _already_ have execute permission.
>     
> 
> This ensures we can browse folders without making text files or disk images executable.

## 4. Grant Default Permissions (Future Files)

The previous command fixed the permissions for everything that _currently_ exists. However, if you create a **new** disk image tomorrow, it will default back to root-only permissions.

To fix this, we set a **Default ACL**. This tells the directory: _"Any new file created inside here must automatically inherit these permissions."_

Notice the `d:` at the start of the permissions string—this stands for "default".

```bash
sudo setfacl -m d:u:$(id -un):rwx /var/lib/libvirt/images
```

## 5. Verify the Changes

Let's check our work. The `getfacl` command reads the permissions back to us.

```
getfacl /var/lib/libvirt/images
```

You should see an output similar to this. Look for the lines containing `user:[your_username]:rwx` and `default:user:[your_username]:rwx`.

```
# file: var/lib/libvirt/images
# owner: root
# group: root
user::rwx
user:madhu:rwx      <-- Your specific access
group::--x
mask::rwx
other::--x
default:user::rwx
default:user:madhu:rwx  <-- Your default access for new files
default:group::--x
default:mask::rwx
default:other::--x
```

## 6. Final Test

Now, try to create a file in that directory as your regular user (without `sudo`).

```
touch /var/lib/libvirt/images/test_file
```

Check the file permissions:

```
ls -l /var/lib/libvirt/images/
```

**Expected Output:**

> total 0
> 
> -rw-rw----+ 1 madhu madhu 0 Feb 12 21:34 test_file

> [!SUCCESS] Done!
> 
> You now have full read/write access to the /var/lib/libvirt/images directory, and any new VMs you create will automatically be accessible by you.