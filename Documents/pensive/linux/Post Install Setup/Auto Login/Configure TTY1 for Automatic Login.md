
We will create a `systemd` override file. This tells the `getty` service, which manages terminal sessions, to automatically log in a specific user on TTY1 (the first virtual console) without asking for a password.

### Step 2.1: Create the Override Directory

First, create the necessary directory for the override file. This command creates the path if it doesn't already exist.

```bash
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d/
```

### Step 2.2: Create and Edit the Override File

Next, create the configuration file itself. You can use any terminal-based text editor you prefer.

```bash
sudo nvim /etc/systemd/system/getty@tty1.service.d/override.conf
```

Add the following content to the file.

> [!NOTE]
> Remember to replace `YOUR_USERNAME` with your actual Linux username.

```ini
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin YOUR_USERNAME --noclear --noissue %I $TERM
```

#### Configuration Breakdown

| Parameter | Description |
| :--- | :--- |
| `[Service]` | Specifies that the following directives apply to the service configuration. |
| `ExecStart=` | The first, empty `ExecStart` clears the default command defined in the original service file. |
| `ExecStart=-...` | The second `ExecStart` defines our new command. The `-` prefix tells `systemd` not to mark the unit as failed if the process exits with an error. |
| `--autologin YOUR_USERNAME` | This is the key flag that performs the automatic login for the specified user. |
| `--noclear` | Prevents `agetty` from clearing the screen before showing the login prompt, which can preserve boot messages. |
| `--noissue` | Prevents `agetty` from displaying the contents of `/etc/issue` before the login. |
