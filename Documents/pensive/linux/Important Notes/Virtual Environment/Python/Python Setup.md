
# Managing Python Versions with `pyenv` on Arch Linux

This guide provides a comprehensive walkthrough for using `pyenv` on Arch Linux to manage multiple Python versions seamlessly. While `venv` is essential for isolating project *packages*, `pyenv` is the industry-standard tool for managing the Python *interpreters* themselves. Using them together provides a robust, conflict-free development environment.

> [!NOTE] `pyenv` vs. `venv`: The Perfect Combination
> - **`pyenv`**: Manages multiple Python versions on your system (e.g., 3.8, 3.10, 3.11). It lets you switch the active Python interpreter globally or for a specific project.
> - **`venv`**: Creates an isolated environment for a project's *packages*, using a specific Python version selected by `pyenv`.
>
> The best practice is to use `pyenv` to choose the Python version, then use that version's built-in `venv` module to create an isolated package environment for your project.

---

## Guide Overview

This collection of notes serves as both a step-by-step setup guide and a quick reference manual. Each section is designed to be self-contained.

### [[Installation and Configuration]]
> A one-time, step-by-step guide to installing `pyenv` and its required build dependencies on Arch Linux. It covers the necessary shell configuration to ensure `pyenv` is properly integrated into your system.

### [[Using pyenv to Manage Python Versions]]
> Covers the daily workflow of `pyenv`. Learn how to install any Python version, set it for global or project-specific use, and follow the standard practice of combining `pyenv` with `venv` for perfect project isolation.

### [[Managing Local & Offline Packages]]
> Details advanced `pip` techniques for situations without internet access or for managing a local cache of packages. This note explains how to download packages, install from a local source, and manage the `pip` cache effectively.

