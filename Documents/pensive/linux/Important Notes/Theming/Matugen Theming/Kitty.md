Copy the kitty-colors.conf template and add it to the matugen config.

```toml
[config]
# ...

[templates.kitty]
input_path = '~/.config/matugen/templates/kitty-colors.conf'
output_path = '~/.config/matugen/generated/kitty-colors.conf'
post_hook = 'ln -nfs $HOME/.config/matugen/generated/kitty-colors.conf $HOME/.config/kitty/kitty-colors.conf; pkill -SIGUSR1 kitty'
```

Then, add this line to the bottom of your `~/.config/kitty/kitty.conf`

```
include kitty-colors.conf
```

