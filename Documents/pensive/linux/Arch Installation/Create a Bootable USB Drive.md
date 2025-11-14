
This guide covers creating a bootable Arch Linux installation medium using **Rufus**, a user-friendly utility for Windows.

### Prerequisites

*   The latest **Arch Linux ISO** file, downloaded from the official website.
*   A **USB drive** (8 GB or larger is recommended).
*   The **Rufus** application.

> [!NOTE] Data Loss Warning
> The following process will erase all data on the selected USB drive. Back up any important files before you begin.

---

### DD Installation (Recommended)

1.  Launch Rufus.
2.  **Device**: Select your target USB drive from the dropdown menu.
3.  **Boot selection**: Click `SELECT` and locate your downloaded Arch Linux `.iso` file.
4.  **Partition scheme**: Keep the default, `GPT`.
5.  **Target system**: Keep the default.
6.  Click **START**.
7. When the pop-up dialog appears, select **Write in DD Image mode**.
8.  Click `OK` to begin writing the image.

>DD mode performs a low-level, direct block-by-block copy and is less flexible.

---
