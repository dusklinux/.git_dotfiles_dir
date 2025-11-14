
# 🔧 Fixing Sluggish Performance on ASUS Laptops

> [!bug] The Problem: A Mysterious Slowdown
> On certain ASUS laptops, a perplexing issue can arise where the entire system grinds to a halt. The root cause is often a custom fan curve that incorrectly limits the maximum processor frequency to the lowest the cpu will alow, in my case, it's 10% of its capacity. For an Intel i7-12700H, this means being stuck at a sluggish `400MHz`.

---

## 🩺 Diagnosis: Confirming the CPU Throttle

Before applying the fix, you can verify if your CPU is being throttled with these simple steps.

### 1. Quick Check with `lscpu`

Run the following command in your terminal and pay close attention to the `CPU(s) scaling MHz:` line. If it's stuck at a very low value (e.g., 400MHz), you've likely found the problem.

```bash
lscpu
```

### 2. Detailed Analysis with `cpupower`

For a more in-depth look, you can use the `cpupower` tool.

> [!tip] First, install `cpupower` if you don't have it:
> ```bash
> sudo pacman --needed -Syu cpupower
> ```

Once installed, run this command to get detailed frequency information:

```bash
cpupower frequency-info
```

---

## ✅ The Solution: Reset the Fan Curve

The fix is surprisingly simple and involves resetting the fan curve to its default setting using `asusctl`. This should resolve the issue almost immediately.

> [!success]+ Click to reveal the command
> Run this command to reset the fan curve to default:
> ```bash
> asusctl fan-curve -d
> ```

> [!info]
> If this specific command doesn't work, explore other fan curve manipulation commands within `asusctl`. Experimenting with them should help restore your PC to its normal, speedy performance.
