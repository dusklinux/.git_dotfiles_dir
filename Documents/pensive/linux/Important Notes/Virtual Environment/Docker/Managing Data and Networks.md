Managing Data and Networks

### The Imperative of Data Persistence
A container's filesystem is temporary. When you remove the container, its data is gone. For anything important (like a database), you must store the data *outside* the container. You have two main options:

> [!grid]
>
> > [!NOTE] Bind Mounts
> > **What it is:** Mapping a specific folder from your host computer directly into the container (e.g., `-v /home/user/my-project:/app`).
> > **Best for:** Development, when you want to edit code on your host and see the changes live in the container.
>
> > [!SUCCESS] Volumes
> > **What it is:** A Docker-managed storage area. You give it a name, and Docker handles where to store it on your host (usually in `/var/lib/docker/volumes/`).
> > **Best for:** All application data that needs to persist, like databases, user uploads, and application state.

> [!TIP] Rule of Thumb
> *   Use **Bind Mounts** for code and config files you edit directly.
> *   Use **Volumes** for all other data your application creates. Volumes are more portable and easier to manage with Docker commands.

### Docker Networking
By default, each container joins a private `bridge` network. They can talk to each other, but are isolated from your host. To expose a service (like a web server), you must "publish" a port with the `-p` flag (e.g., `-p 8080:80`), which connects a port on your host to a port in the container.

---
