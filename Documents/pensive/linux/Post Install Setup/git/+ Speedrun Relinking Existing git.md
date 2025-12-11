```bash
rm -rf $HOME/dusky
```

```bash
git config --global user.name "dusk" && git config --global user.email "dusk1@myyahoo.com" && git config --global init.defaultBranch main
```

```bash
ssh-keygen -t ed25519 -C "dusk1@myyahoo.com"
```

```bash
eval "$(ssh-agent -s)"
```

```bash
cat ~/.ssh/id_ed25519.pub
```

save to pgp key on github

```bash
git clone --bare git@github.com:dusklinux/dusky.git $HOME/dusky
```

type yes

```bash
git_dusky config --local status.showUntrackedFiles no
```

```bash
git_dusky status
```

```bash
git_dusky reset
```

```bash
git_dusky status
```

```bash
git_dusky_add_list && git_dusky commit -m "fresh install first commit to the same old git repo"
```

```bash
git_dusky remote add origin git@github.com:dusklinux/dusky.git
```

```bash
git_dusky remote set-url origin git@github.com:dusklinux/dusky.git
```

```bash
ssh -T git@github.com
```

```bash
git_dusky push -u origin main
```