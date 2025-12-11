Follow these steps to deploy your dotfiles onto a new machine.

1.  **Clone the Bare Repository.**

```bash
git clone --bare --depth 1 https://github.com/dusklinux/dusky.git $HOME/dusky
```

2.  Populate the files on your system from the downloaded bare repo. checkout will automatically put all files in there intended places. This command will populate your `$HOME` directory with the files from the repository.

```bash
/usr/bin/git --git-dir=$HOME/dusky/ --work-tree=$HOME checkout -f
```


> [!WARNING]- Potential for Overwriting Files
> It is often what you want on a fresh system, but consider backing up the default files first.


3. After deploying the files to your PC and after you've confirmed the files to have populated on your system, delete the bare repo

```bash
rm -rf ~/dusky
```
