# ⚡️ UV: A Comprehensive Guide to Blazing-Fast Python Environments

Welcome to your central hub for mastering `uv`, the blazingly fast Python package installer and resolver. Written in Rust, `uv` is a modern, drop-in replacement for `pip` and `venv` that will supercharge your development workflow on Arch Linux and beyond.

This note serves as a map of content (MOC) to navigate all related guides and references.

---

## 🧠 Foundational Concepts

Before diving into `uv`, it's crucial to understand *why* virtual environments are essential. This note demystifies the core principles, ensuring you use these tools with confidence and precision.

> [!NOTE] Deep Dive: How Virtual Environments Work
> [[Understanding Virtual Environments]]
> Learn what "activating" an environment *really* does, how isolation is enforced through shebangs and hard-wired interpreters, and the best practices for managing project dependencies.

---

## 🚀 Core Workflow & Guides

Navigate through the essential guides for using `uv` in your day-to-day projects. Start here if you're new to `uv` or need a refresher on the main workflow.

> [!TIP] Getting Started: Your First `uv` Project
> [[Creating UV Virtual Environment]]
> A step-by-step tutorial on initializing a new project, creating and activating a virtual environment, installing packages, and freezing dependencies for reproducibility.

> [!INFO] Everyday Usage: Managing Packages
> [[Package Management UV]]
> Explore the full suite of `uv pip` commands. This guide covers installing, upgrading, removing, and inspecting packages, along with the critical difference between `install` and `sync`.

> [!SUCCESS] Advanced Execution: Ephemeral Commands
> [[Ephemeral Command Execution uvx]]
> Discover `uvx`, the powerful utility for running Python tools in temporary, self-destructing environments. Perfect for linters, formatters, and one-off scripts without polluting your project.

---

## 📚 Quick Reference

For when you know what you want to do but just need to look up the exact command.

> [!abstract] Complete Command Reference
> [[Command Reference UV]]
> A comprehensive cheat sheet for all major `uv` commands, including environment management (`uv venv`), package management (`uv pip`), and cache control.


> [!TIP] Put your packages in single quotes when installing them, this prevents the command from failing.
> ```bash
> uv pip install 'pytorch'
> ```
> see [[Troubleshooting Virtual Environments]] for more info. 


> [!note] Numpy error fix eg for a specific version
> ```bash
> uv pip install numpy==1.26.4 --force-reinstall
> ```