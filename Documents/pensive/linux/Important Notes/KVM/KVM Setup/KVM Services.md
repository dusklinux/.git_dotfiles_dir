# KVM Service Configuration

Before we can create or run any virtual machines, we need to start the specific system services that manage them. Think of these services (daemons) as the "engine" running in the background that powers your KVM setup.

We will be dealing with two primary services:


| **Service** | **Description**                                                                                                                                                                             |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `libvirtd`  | **The Main Engine.** This daemon manages your Virtual Machines, networks, and storage. It acts as the translator between you (using software like Virt-Manager) and the actual hardware.    |
| `virtlogd`  | **The Scribe.** This handles the logging of VM output. It is separated from the main engine so that if the logs get cluttered or crash, it doesn't take down your running Virtual Machines. |

## Enabling the Services

We need to tell Arch Linux to start these services now and ensure they start automatically every time you turn on your computer.

Run the following command in your terminal:

```bash
sudo systemctl enable --now libvirtd.service virtlogd.service
```

> [!TIP] Understanding the Command
> 
> You will notice we used the --now flag in the command above.
> 
> - **enable**: Tells the system to start this service automatically next time you reboot.
>     
> - **--now**: Tells the system to _also_ start it immediately right now, without waiting for a reboot.
>