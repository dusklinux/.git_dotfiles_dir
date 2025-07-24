# Guide to ASUS Hardware Control with `asusctl`

This guide provides a comprehensive overview of common `asusctl` commands for managing hardware features on ASUS laptops running Arch Linux. The commands are categorized for easy navigation and include explanations to help you understand and customize them for your needs.

> [!NOTE] System Information
> The following configuration is based on an **ASUS TUF Gaming F15 (FX507ZE)**. Some commands or features may vary depending on your specific laptop model.
>
> - **`asusctl` version:** `6.1.12`
> - **Supported Interfaces:** `Aura`, `FanCurves`, `Backlight`, `Platform`

---

## 1. Fan Control & Performance Profiles

Manage your laptop's cooling and performance by setting custom fan curves and switching between power profiles.

### Listing Active Profiles

To check which performance profile is currently active, use the following command:

```bash
sudo asusctl profile -p
```

### Custom Fan Curves

A fan curve defines how fast the fans should spin at different temperatures. This allows you to balance cooling performance with noise levels.

> [!TIP] Understanding the `fan-curve` Command
> `sudo asusctl fan-curve [options]`
> - `-E true`: Enables the custom fan curve.
> - `-m performance`: Applies the curve to the "Performance" profile.
> - `-f cpu` or `-f gpu`: Specifies whether to target the CPU or GPU fan.
> - `-D ...`: Defines the curve as a comma-separated list of `temperature_celsius:fan_speed_%`.

#### Balanced Performance Curve

This is a sensible curve for everyday use and gaming, providing good cooling without being excessively loud.

**Set GPU Fan Curve:**
```bash
sudo asusctl fan-curve -E true -m performance -f gpu -D 30c:20%,55c:40%,59c:45%,62c:50%,65c:57%,67c:60%,70c:70%,72c:85%
```

**Set CPU Fan Curve:**
```bash
sudo asusctl fan-curve -E true -m performance -f cpu -D 30c:20%,55c:40%,59c:45%,62c:50%,65c:57%,67c:60%,70c:70%,72c:85%
```

#### Maximum Fan Speed (100%)

Use this profile for demanding tasks where maximum cooling is required, such as benchmarking or intense gaming sessions.

> [!WARNING]
> This will make your fans very loud. It is intended for short-term use when maximum cooling is critical.

**Set GPU Fan to 100%:**
```bash
sudo asusctl fan-curve -E true -m performance -f gpu -D 30c:100%,55c:100%,59c:100%,62c:100%,65c:100%,67c:100%,70c:100%,72c:100%
```

**Set CPU Fan to 100%:**
```bash
sudo asusctl fan-curve -E true -m performance -f cpu -D 30c:100%,55c:100%,59c:100%,62c:100%,65c:100%,67c:100%,70c:100%,72c:100%
```

---

## 2. Keyboard Aura (RGB) Control

Customize your keyboard's backlighting with static colors. The `asusctl aura static` command sets the entire keyboard to a single color using a hex code.

> [!TIP] Find Your Perfect Color
> You can use any 6-digit hex color code. Use an online tool like [Google Color Picker](https://www.google.com/search?q=color+picker) to find the perfect shade.

### Color Command Reference

Here is a list of pre-selected colors and the commands to apply them. Your favorite, **Burnt Orange**, is highlighted.

| Color Name | Preview | Hex Code | Command to Copy |
|---|---|---|---|
| **Burnt Orange (Fav)** | <span style="color:#cc5500">■■■</span> | `cc5500` | `sudo asusctl aura static -c cc5500` |
| Pure White | <span style="color:#ffffff">■■■</span> | `ffffff` | `sudo asusctl aura static -c ffffff` |
| Crimson Red | <span style="color:#dc143c">■■■</span> | `dc143c` | `sudo asusctl aura static -c dc143c` |
| Cyberpunk Cyan | <span style="color:#00ffff">■■■</span> | `00ffff` | `sudo asusctl aura static -c 00ffff` |
| Royal Blue | <span style="color:#4169e1">■■■</span> | `4169e1` | `sudo asusctl aura static -c 4169e1` |
| Forest Green | <span style="color:#228b22">■■■</span> | `228b22` | `sudo asusctl aura static -c 228b22` |
| Gold | <span style="color:#ffd700">■■■</span> | `ffd700` | `sudo asusctl aura static -c ffd700` |
| Hot Pink | <span style="color:#ff69b4">■■■</span> | `ff69b4` | `sudo asusctl aura static -c ff69b4` |
| Royal Purple | <span style="color:#800080">■■■</span> | `800080` | `sudo asusctl aura static -c 800080` |
| Slate Gray | <span style="color:#708090">■■■</span> | `708090` | `sudo asusctl aura static -c 708090` |

<details>
<summary>Click for an extended list of color commands</summary>

| Color Name | Hex Code | Command to Copy |
|---|---|---|
| Blood Red | `880808` | `sudo asusctl aura static -c 880808` |
| Lime Green | `00ff00` | `sudo asusctl aura static -c 00ff00` |
| Deep Blue | `0000ff` | `sudo asusctl aura static -c 0000ff` |
| Electric Yellow | `ffff00` | `sudo asusctl aura static -c ffff00` |
| Turquoise | `40e0d0` | `sudo asusctl aura static -c 40e0d0` |
| Shocking Magenta | `ff00ff` | `sudo asusctl aura static -c ff00ff` |
| Vibrant Orange | `ffa500` | `sudo asusctl aura static -c ffa500` |
| Indigo | `4b0082` | `sudo asusctl aura static -c 4b0082` |
| Violet | `ee82ee` | `sudo asusctl aura static -c ee82ee` |
| Lavender | `e6e6fa` | `sudo asusctl aura static -c e6e6fa` |
| Sky Blue | `87ceeb` | `sudo asusctl aura static -c 87ceeb` |
| Steel Blue | `4682b4` | `sudo asusctl aura static -c 4682b4` |
| Navy Blue | `000080` | `sudo asusctl aura static -c 000080` |
| Maroon | `800000` | `sudo asusctl aura static -c 800000` |
| Teal | `008080` | `sudo asusctl aura static -c 008080` |
| Coral | `ff7f50` | `sudo asusctl aura static -c ff7f50` |
| Mint Green | `98ff98` | `sudo asusctl aura static -c 98ff98` |
| Chartreuse | `7fff00` | `sudo asusctl aura static -c 7fff00` |
| Plum | `dda0dd` | `sudo asusctl aura static -c dda0dd` |
| Silver | `c0c0c0` | `sudo asusctl aura static -c c0c0c0` |

</details>

---

