### Step 1: Prerequisites — Global Git Configuration

Before you begin, ensure your Git identity is configured. This information is embedded into every commit you make.

> [!NOTE] One-Time Setup
> These commands only need to be run once on any new machine. The `--global` flag applies these settings to all Git repositories for your user account.

1.  **Set Your User Name:**
```bash
git config --global user.name "dusk"
```

2.  **Set Your Email Address:**
```bash
git config --global user.email "dusk1@myyahoo.com"
```

3.  **Set the Default Branch to `main`:**
- It is modern convention to use `main` as the default branch name instead of `master`. This command ensures all new repositories you initialize will default to `main`.

```bash
git config --global init.defaultBranch main
```