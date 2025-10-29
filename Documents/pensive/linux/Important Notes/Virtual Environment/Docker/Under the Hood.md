The "How" - Under the Hood

Docker feels like magic, but it's just clever use of features already built into the Linux kernel. Unlike a VM, a container does **not** run its own operating system. It shares the kernel of your host machine (your Arch Linux). This is why it's so fast and lightweight.

The "magic" of isolation is created by two core Linux technologies:

#### Pillar 1: Namespaces (Isolating What a Container Can *See*)

Namespaces act like blinders for a process. They trick a process inside a container into thinking it has its own private system.

| Namespace | What It Isolates | Simple Explanation |
|---|---|---|
| **PID** (Process ID) | Processes | The container thinks it's the only thing running. Its main process gets ID #1, just like the `init` process on a full OS. It can't see or affect other processes on your computer. |
| **NET** (Network) | Networking | The container gets its own private network, with its own IP address and network ports. This is why you can run two web servers on port 80 in two different containers without a conflict. |
| **MNT** (Mount) | Filesystem | The container gets its own private filesystem, based on its image. It can't see the files on your host computer unless you explicitly allow it. |
| **UTS** (Hostname) | Hostname | The container gets its own hostname, so it doesn't think it's named `archlinux`. |
| **IPC** & **USER** | Communication & Users | These isolate inter-process communication and user accounts, further enhancing security and separation. |

#### Pillar 2: Control Groups (cgroups) (Limiting What a Container Can *Use*)

While namespaces handle what a container can *see*, cgroups handle what it can *use*. They are like a resource budget for a container.

You can tell Docker:
*   "This container can use a maximum of 1 CPU core."
*   "This container can use no more than 512MB of RAM."
*   "Limit this container's disk read/write speed."

This prevents a single runaway container from crashing your entire system.

### Architecture: VM vs. Docker

This visual summary makes the difference clear.

> [!grid]
>
> > [!NOTE] Virtual Machine Architecture (Heavyweight)
> > ```
> > +---------------------+
> > |     Application     |
> > +---------------------+
> > |   Guest OS/Kernel   |
> > +---------------------+
> > |     Hypervisor      |
> > +---------------------+
> > |   Host OS (Arch)    |
> > +---------------------+
> > |      Hardware       |
> > +---------------------+
> > ```
>
> > [!SUCCESS] Docker Container Architecture (Lightweight)
> > ```
> > +-----------+ +-----------+
> > |  App A    | |  App B    |
> > +-----------+ +-----------+
> > |       Docker Engine     |
> > +-------------------------+
> > | Host OS (Arch) & Kernel |
> > +-------------------------+
> > |         Hardware        |
> > +-------------------------+
> > ```

### The Layered Filesystem: Copy-on-Write

Docker images are built in layers. When you change one line in a `Dockerfile` and rebuild, only that one layer is changed. When you run a container, it uses the read-only layers from the image and adds a thin, writable layer on top.

If you try to change a file from a lower layer, Docker uses a **Copy-on-Write (CoW)** strategy: it copies the file up to the writable top layer and then modifies the copy. The original image remains untouched.

This is extremely efficient for both disk space and speed.

> [!TIP] A Note on BTRFS
> Since your system uses the BTRFS filesystem, Docker can leverage its native `snapshot` feature. This makes creating image layers and container writable layers almost instantaneous and incredibly space-efficient, making Docker even more performant on your machine.

---
