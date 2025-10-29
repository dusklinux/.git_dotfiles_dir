
This optional step is for modifying an existing user account, typically to grant permissions for specific applications by adding the user to supplementary groups. This is a common requirement after installing software like Docker, libvirt (for virtualization), or Ollama.

> [!NOTE]
> Your user should already be a member of the `wheel` group from the [[User Account Creation]] step, which grants administrative privileges via `sudo`. This section covers adding the user to *other* groups for application-specific permissions.

### Command

Use the `usermod` command to add a user to one or more groups. Replace `your_username` with the actual username.

```bash
usermod -aG group your_username
```

**Command Breakdown**

| Component | Description |
| :--- | :--- |
| `usermod` | The command to **mod**ify a **user** account. |
| `-aG` | The `-a` (append) flag adds the user to the supplementary **G**roups specified, without removing them from existing ones. |
| `group1,...` | A comma-separated list of groups to join. |

> [!WARNING]
> Always use the `-a` (append) flag with `-G`. Forgetting `-a` will *remove* the user from all groups not listed, including the essential `wheel` group, revoking their `sudo` access.

### Example Usage

To grant a user access to Docker, libvirt, and Ollama, add them to the corresponding groups:

```bash
usermod -aG docker,libvirt,ollama your_username
```

> [!TIP]
> For group membership changes to take effect, the user must log out and log back in. (this is if you're alerdy booted into the os post install. )

