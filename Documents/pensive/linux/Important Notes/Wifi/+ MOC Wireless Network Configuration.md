
Connecting to the internet is a critical step in any Arch Linux setup. This guide provides a summary of three common tools for managing wireless network connections. Each offers a different approach, from comprehensive daemons to lightweight, focused utilities.

For detailed, step-by-step instructions, please refer to the individual notes linked below.

---

### Comparison of Wireless Tools

| Tool | Primary Interface | Description | Best For |
|:---|:---|:---|:---|
| [[Network Manager]] | `nmcli` | A powerful, full-featured network management daemon that handles wired, wireless, and mobile broadband connections automatically. | Desktops, laptops, and users who prefer a "just works" experience with extensive features. |
| [[Connmanctl]] | `connmanctl` | A lightweight and fast network manager, originally designed for embedded systems. | Users seeking a minimal resource footprint without sacrificing essential functionality. |
| [[IWD]] | `iwctl` | A modern, lightweight wireless daemon from Intel, designed to replace `wpa_supplicant`. | The Arch Linux installation environment and users who prefer a simple, dedicated wireless client. |

---

### Tool Summaries

#### [[Network Manager]]
NetworkManager is the most popular and feature-rich option for managing network connections on Linux. It operates as a background service (`NetworkManager.service`) and can automatically detect and configure network devices using its powerful command-line tool, `nmcli`.

> [!TIP]
> NetworkManager is ideal for day-to-day use on a desktop or laptop, as it seamlessly manages switching between different networks. For detailed commands, see the [[Network Manager]] note.

#### [[Connmanctl]]
ConnMan is a daemon designed to be lean and fast, providing stable internet connectivity with minimal overhead. It uses an interactive command-line tool, `connmanctl`, for configuration.

> [!NOTE]
> ConnMan is a great choice for systems where resource usage is a primary concern. The connection process within `connmanctl` is interactive, requiring you to enable Wi-Fi, scan, and connect. See the [[Connmanctl]] note for the command sequence.

#### [[IWD]]
`iwd` (iNet wireless daemon) is a modern replacement for `wpa_supplicant`, focused solely on managing wireless connections. It is the recommended tool for connecting to Wi-Fi during the Arch Linux installation process due to its simplicity and minimal dependencies.

> [!SUCCESS]
> The [[IWD]] note contains a complete, step-by-step guide perfect for getting connected for the first time using its interactive `iwctl` shell.

