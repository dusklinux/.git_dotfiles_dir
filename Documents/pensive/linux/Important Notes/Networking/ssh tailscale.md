# Elite Remote Access: Granting Guest SSH Access

> [!abstract] Overview
> 
> How to allow a friend or colleague to SSH into your Arch machine securely, without giving them your personal passwords or full network access.

## 🛡️ Layer 1: The Network (Tailscale Sharing)

Instead of giving them your Tailscale login, you will generate an "Invite Link" that allows _their_ Tailscale account to see _your_ specific machine.

1. Go to the Admin Console:
    
    Open login.tailscale.com/admin/machines in your browser.
    
2. Locate your Machine:
    
    Find your Arch laptop in the list.
    
3. **Share:**
    
    - Click the **Three Dots (`...`)** on the right side of your machine.
        
    - Select **Share**.
        
    - Click **"Generate verify link"**.
        
4. Send the Link:
    
    Copy that link and send it to your friend.
    
    - Once they click it and sign in with _their_ account, your machine (`100.103.155.65`) will appear in their Tailscale list.
        
    - They can now "ping" you, but they cannot "login" yet.
        

## 🔑 Layer 2: The Authentication (SSH Keys)

Now that they can reach your door, you need to give them a key to open it. **Do not use passwords.** Ask your friend to send you their **Public SSH Key** (it usually starts with `ssh-ed25519` or `ssh-rsa`).

### Option A: The "Trust Me" Method (Same User)

_Use this only if you trust them completely with your files._

Run this on your Arch laptop:

```
# Replace the text inside quotes with the key they sent you
echo "ssh-ed25519 AAAA-THEIR-KEY-HERE friend@email.com" >> ~/.ssh/authorized_keys
```

- **They connect via:** `ssh dusk@100.103.155.65`
    
- **Risk:** They have access to all your files.
    

### Option B: The "Guest User" Method (Elite/Secure)

_This creates a sandboxed room for them._

1. **Create a new user:**
    
    ```
    # Create user 'guest' with a home directory
    sudo useradd -m -s /bin/bash guest
    ```
    
2. **Set up their SSH access:**
    
    ```
    # Switch to the guest account temporarily
    sudo -u guest mkdir -p /home/guest/.ssh
    sudo -u guest touch /home/guest/.ssh/authorized_keys
    
    # Add their key (Use the text editor nano to paste it in)
    sudo -u guest nano /home/guest/.ssh/authorized_keys
    ```