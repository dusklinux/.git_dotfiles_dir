i need you to create a script for arch linux running hyprland to toggle blur and opacity at once, i want you to only correct the enabled = either either false or true depending on which one it's at. and if blur is disabled, i want you to also disable transparency by setting both active_opacity and inactive_opacity to = 1.0 and if blur is enabled, i want you to set active_opacity to 0.7 and inactive opacity to 0.5 

i don't want you to change anything else in the config file. the file is at this path. 
```bash
$HOME/.config/hypr/source/appearance.conf
```

btw there are multiple lines with enabled = true/false, only change the one for the blur not others so make sure you check it's for blur. and not anything else. on the other hand opacity lines are unique. so you can change them without looking for the context. 
```ini
    blur {
        enabled = false
```

```ini
    active_opacity = 1.0
    inactive_opacity = 1.0
```

make sure this script is incredibly robust. and addresses edge cases. also don't create any logging, don't create any backup files. i want this script to be clean it's going to be run with a keybind quietly. make sure it works. it's incredibly consequential that you get this right. or there will be grave consequences. 

also allow setting the opacity uptop as a variable.

so here's the logic, if blur is disabled, enable it,  and also turn on transpirancy, 
if blur is enabled, disable it, and also turn off transpirancy. 