- Add the .css file to matugen's templates directory.
- Add the this to matugen configs with the correct paths.

```toml
[templates.Obsidian]
input_path = '~/.config/matugen/templates/obsidian-theme.css'
output_path = '~/.config/matugen/generated/obsidian-theme.css'
post_hook = 'ln -nfs $HOME/.config/matugen/generated/obsidian-theme.css $HOME/Documents/pensive/.obsidian/snippets/matugen-theme.css'
```


> [!important] Activate the snippet created inside obsidian settings.
