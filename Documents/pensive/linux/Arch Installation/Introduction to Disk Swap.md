### Introduction to Disk Swap

A **swap partition** (or swap file) is a space on a disk that the Linux kernel uses as virtual memory. When your system's physical RAM (Random Access Memory) is full, the kernel moves inactive pages of memory to the swap space, freeing up RAM for active processes.

**Key Use Cases:**
*   **Extending RAM:** Prevents system instability or crashes when physical memory is exhausted.
*   **Hibernation:** Allows the system to save the entire state of RAM to the disk before powering off, enabling a quick resume.

> [!NOTE] Relationship with ZRAM
> While disk swap is useful, it is significantly slower than RAM. For performance, it's highly recommended to use [[ZRAM Setup]] as your primary swap mechanism. ZRAM creates a compressed swap device directly in your RAM, which is orders of magnitude faster.
>
> A common and effective strategy is to use both:
> 1.  **ZRAM:** As a high-priority swap for performance.
> 2.  **Disk Swap:** As a low-priority fallback and/or for enabling hibernation.
