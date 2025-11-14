git commands

This guide serves as a practical manual for using Git on any system, including Arch Linux. It covers everything from initial setup to daily workflows and advanced operations, designed to be both a step-by-step tutorial and a quick reference.

---

## 1. Initial Configuration

Before you start using Git, you need to configure it with your personal information. This is a one-time setup on any new machine.

> [!NOTE] Global vs. Local Config
> The `--global` flag applies the configuration to every repository on your system. To set it for only the current repository, omit the `--global` flag.

#### Set Your Identity
This information is embedded into every commit you make.

```bash
git config --global user.name "Your Name"
git config --global user.email "youremail@example.com"
```

#### Set the Default Branch Name
Modern Git practices use `main` as the default branch name instead of `master`. This command ensures any new repository you create with `git init` uses `main`.

```bash
git config --global init.defaultBranch main
```

---

## 2. The Core Workflow

This section covers the fundamental commands you'll use every day.

| Command | Description |
| :--- | :--- |
| `git init` | Initializes a new, empty Git repository in the current directory. |
| `git clone <url>` | Creates a local copy of a remote repository on your machine. |
| `git status` | Shows the current state of your working directory and staging area. |
| `git add <file>` | Adds a specific file's changes to the staging area. |
| `git add .` | Adds all new and modified files in the current directory to the staging area. |
| `git add -p` | Interactively stages parts ("hunks") of files, giving you fine-grained control. |
| `git commit -m "Message"` | Saves the staged changes to the repository's history with a descriptive message. |

---

## 3. Branching & Merging

Branches allow you to work on different features or fixes in isolation without affecting the main codebase.

| Command | Description |
| :--- | :--- |
| `git branch` | Lists all local branches. The current branch is marked with an asterisk (*). |
| `git branch <branch-name>` | Creates a new branch from the current commit. |
| `git switch <branch-name>` | Switches your working directory to the specified branch. |
| `git switch -c <branch-name>` | A convenient shortcut that creates a new branch and immediately switches to it. |
| `git branch -m <old> <new>` | Renames a branch. |
| `git merge <branch-name>` | Integrates changes from `<branch-name>` into your current branch. |
| `git branch -d <branch-name>` | Deletes a local branch. Use `-D` to force delete an unmerged branch. |

> [!TIP] A Typical Merge Workflow
> To merge a `new-feature` branch into `main`:
> ```bash
> # 1. Switch to the receiving branch
> git switch main
> 
> # 2. Pull the latest changes from the remote to avoid conflicts
> git pull
> 
> # 3. Perform the merge
> git merge new-feature
> ```

---

## 4. Working with Remotes

Remotes are versions of your repository that live on other servers (like GitHub or GitLab).

| Command | Description |
| :--- | :--- |
| `git remote -v` | Lists all configured remote repositories with their URLs. |
| `git remote add <name> <url>` | Adds a new remote repository under a shorthand `<name>` (e.g., `origin`). |
| `git fetch <remote>` | Downloads all new data from a remote but does **not** integrate it into your local branches. |
| `git pull <remote> <branch>` | Fetches changes from the remote and immediately merges them into your current branch. It's a shortcut for `git fetch` followed by `git merge`. |
| `git push -u <remote> <branch>` | Uploads your local commits to a remote branch. The `-u` flag sets up a tracking relationship for future pushes. |
| `git push <remote> --delete <branch>` | Deletes a branch on the remote repository. |

---

## 5. Inspecting the Repository

These commands help you understand the history and the changes within your project.

#### Viewing Commit History (`git log`)
The `git log` command is highly customizable. Here are some useful variations:

```bash
# View a condensed log with one commit per line
git log --oneline

# Display the log as a visual graph, showing branches and merges
git log --graph --oneline --decorate
```

#### Viewing Differences (`git diff`)
`git diff` shows changes between commits, branches, or files.

| Command | Description |
| :--- | :--- |
| `git diff` | Shows unstaged changes (Working Directory vs. Staging Area). |
| `git diff --staged` | Shows staged changes (Staging Area vs. Last Commit/HEAD). |
| `git diff HEAD` | Shows all changes, both staged and unstaged (Working Directory vs. Last Commit/HEAD). |

---

## 6. Undoing Changes & Rewriting History

Mistakes happen. Git provides powerful tools to fix them. It's crucial to distinguish between safe and destructive methods.

> [!WARNING] Rewriting Public History
> Never use commands that rewrite history (like `git reset` or `git rebase`) on branches that have been pushed and are shared with others. Use `git revert` instead.

### The Safe Undo: `git revert`
`git revert` creates a **new commit** that is the inverse of a previous commit. This is the safest way to undo changes on a public branch because it preserves the project's history.

```bash
# 1. Find the hash of the commit you want to undo
git log --oneline

# 2. Create a new commit that undoes the changes from the target commit
git revert <commit-hash>
```

### Amending the Last Commit
If you made a mistake in your most recent commit message or forgot to include a file, you can "amend" it. This rewrites the last commit.

> [!NOTE]
> This is safe to do on commits you have **not yet pushed** to a remote.

```bash
# Add any forgotten files first
git add forgotten-file.txt

# Amend the previous commit, opening your editor to change the message
git commit --amend

# Or, amend and change the message directly from the command line
git commit --amend -m "A new, corrected commit message"
```

### The Powerful Undo: `git reset`
`git reset` moves the current branch pointer to a different commit, potentially discarding history. This is a powerful but destructive tool.

| Mode | Effect on Commits | Effect on Staging Area | Effect on Working Directory | Use Case |
| :--- | :--- | :--- | :--- | :--- |
| `--soft` | Discarded | **Unchanged**. Staged changes from discarded commits remain staged. | Unchanged | Combine several recent commits into one. |
| `--mixed` | Discarded | **Reset**. Changes from discarded commits are moved to the working directory. | Unchanged | Uncommit changes but keep them to re-work. |
| `--hard` | Discarded | **Reset**. | **Reset**. All changes are **permanently deleted**. | Throw away recent commits and all associated work. |

**Example Commands:**
```bash
# Move back one commit, keeping all changes staged
git reset --soft HEAD~1

# Move back one commit, keeping changes in the working directory (unstaged)
git reset --mixed HEAD~1

# DANGER: Permanently delete the last commit and all its changes
git reset --hard HEAD~1
```

---

## 7. Temporarily Stashing Changes

Use `git stash` to save uncommitted changes temporarily, allowing you to switch branches without committing incomplete work.

| Command | Description |
| :--- | :--- |
| `git stash` | Saves your uncommitted changes (staged and unstaged) to a stash. |
| `git stash list` | Shows all the stashes you have saved. |
| `git stash apply` | Applies the most recent stash but keeps it in your stash list. |
| `git stash pop` | Applies the most recent stash and removes it from your stash list. |

