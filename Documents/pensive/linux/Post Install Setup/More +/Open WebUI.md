

# 🚀 Open WebUI: A Step-by-Step Setup Guide

This guide provides a clear, methodical walkthrough for installing and running Open WebUI in an isolated Python environment using `uv`.

---

### Step 1: Prepare the Project Directory

First, we need a dedicated directory to house our application and its virtual environment. This keeps your projects organized and self-contained.

> [!TIP] The `-p` Flag
> The `mkdir -p` command is a safe way to create directories. It will create the entire path if it doesn't exist and won't throw an error if it already does.

Execute the following commands to create and navigate into the directory:

```bash
mkdir -p ~/contained_apps/uv/
cd ~/contained_apps/uv/
```

---

### Step 2: Create and Activate the Virtual Environment

Next, we'll create a dedicated virtual environment named `open_web_ui` using a specific Python version. This ensures that Open WebUI's dependencies won't conflict with other Python projects on your system. For more details on this process, see [[Creating UV Virtual Environment]].

1.  **Initialize the Environment**
    This command creates a new virtual environment using Python 3.11.

    ```bash
    uv venv open_web_ui --python 3.11
    ```

2.  **Activate the Environment**
    Activation configures your shell to use the Python interpreter and packages from this specific environment.

    ```bash
    source open_web_ui/bin/activate
    ```

    > [!NOTE]
    > Your shell prompt should now be prefixed with `(open_web_ui)`, indicating that the virtual environment is active.

---

### Step 3: Install and Run Open WebUI

With the environment active, we can now install and launch the application.

1.  **Install the Package**
    Use `uv pip install` to download and install Open WebUI. `uv` will handle resolving and installing all necessary dependencies at high speed.

    ```bash
    uv pip install open-webui
    ```

2.  **Start the Server**
    Once the installation is complete, start the web server with the `serve` command.

    ```bash
    open-webui serve
    ```

    > [!SUCCESS] Server is Live!
    > If successful, the terminal will indicate that the server is running. You can now access the user interface in your web browser.

---

### Step 4: First-Time Login

Open your web browser and navigate to the local address where the server is being hosted.

*   **URL:** `http://localhost:8080`

On your first visit, you will be prompted to create an administrator account.

> [!WARNING] Default Credentials
> The following credentials are for initial setup and testing only. For any persistent or shared instance, be sure to use a strong, unique password.

Use the following details to sign up:

| Field    | Value             |
| :------- | :---------------- |
| **Email**  | `testing@gmail.com` |
| **Username** | `testing`           |
| **Password** | `testing`           |

You are now ready to use Open WebUI

