# 🤖 Waydroid on Arch Linux: A Comprehensive Guide

> [!abstract]
> Welcome to your central hub for installing, configuring, and mastering Waydroid. Waydroid is a container-based solution that allows you to run a full Android operating system directly on your Linux machine, offering near-native performance. This collection of notes provides a step-by-step path from initial setup to advanced configuration and troubleshooting.

---

## Your Waydroid Journey

Follow these guides in order to get a fully functional Android environment on your system. Each note builds upon the last, ensuring a smooth and logical workflow.

> [!todo]- [[Waydroid Setup]]
> **Start Here: The Foundation.** This note walks you through the essential first steps. You will learn how to prepare your system, install the Waydroid package, manually place the required Android system and vendor images, and perform the initial initialization to get your container up and running for the first time.

> [!bug]- [[Waydroid Rooting]]
> **Advanced Configuration & Troubleshooting.** Once Waydroid is running, this guide covers the next level of customization and problem-solving. It details how to root your instance using community scripts, enable features like Zygisk, and solve common issues such as fixing network connectivity with `firewalld`, sharing folders between your host and Waydroid, and correcting file permissions.

---

## Conclusion

> [!summary]
> Waydroid leverages core Linux kernel features (like namespaces) to run Android in a lightweight container, sharing the kernel with your host system. This approach makes it significantly more efficient and performant than traditional emulators. By following this guide, you will have a powerful tool for running Android applications seamlessly on your Arch Linux desktop.
