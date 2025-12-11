### Step 2: Initialize the Bare Repository

First, initialize a "bare" Git repository. Unlike a standard repository, a bare repository has no working tree (no checked-out files); it only contains the Git version history and data, making it ideal for use as a central backup location.

```bash
git init --bare $HOME/dusky
```
