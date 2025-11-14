### Pywalfox

```toml
[config]

[templates.pywalfox]
input_path = '~/.config/matugen/templates/pywalfox-colors.json'
output_path = '~/.config/matugen/generated/pywalfox-colors.json'
post_hook = 'ln -nfs $HOME/.config/matugen/generated/pywalfox-colors.json $HOME/.cache/wal/colors.json; pywalfox update'
```

Note

Add the [Pywalfox plugin](https://addons.mozilla.org/en-US/firefox/addon/pywalfox/) to firefox / thunderbird.  
Dependencies: [pywalfox](https://github.com/frewacom/pywalfox)  
Install:

```bash
mkdir -p $HOME/.cache/wal
```

- Arch (AUR): 

```bash
paru --needed -S python-pywalfox
```

That's it!