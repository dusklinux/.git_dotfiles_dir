---
subject: font 
context:
  - setup
  - arch install
type: guide
status: complete
---


During the Arch Linux installation process, you might find the default console font too small to read comfortably, especially on high-resolution displays. You can easily switch to a larger font for better visibility.

## Set a Larger Font

To change the console font, use the `setfont` command. The `latarcyrheb-sun32` font is a good, large, and readable option.

```bash
setfont latarcyrheb-sun32
```

> [!TIP] Discovering Other Fonts
> You can list all available console fonts to find one that you prefer. Use the following command to see your options:
> ```bash
> ls /usr/share/kbd/consolefonts/
> ```
> You can then use `setfont` with any font name from that list.

> [!NOTE] Temporary Change
> This font change is temporary and only applies to the current live session. It will not persist after a reboot or into the final installed system.