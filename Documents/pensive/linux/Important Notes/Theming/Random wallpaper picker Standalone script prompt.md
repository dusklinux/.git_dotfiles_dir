
make sure to check if swww is installed first . 
create a script for arch linux to switch wallpapers for the current theme. i have a lot of theme directories so to make sure you pick a wallpaper from the current theme directory first look for the currently set theme 

for the myTheme place holder directory make sure to look for the current set theme by the user in this path , there will on be just the name of the directory and nothing else . replace myTheme with the directory name from the text file obviously. 
```bash
$HOME/.config/theming/user_set_theme.txt
```

this will be the wallpaper directory for each theme
obviously replace the myTheme placeholder with the text you found earlier from the text file. 
```bash
$HOME/.config/theming/all_themes/myTheme/wallpaper/
```

wallaper changing  (There might be more than one wallpaper in each directroy for wallpaper for every theme so pick one at random to keep it fresh, if there is only one wallpaper, then just apply that wallpaper) replace myTheme with the actual theme name 

```bash
swww img $HOME/.config/theming/all_themes/myTheme/wallpaper/* --transition-type grow --transition-duration 2 --transition-fps 60
```

if there are any edge cases you can think of to fix this, implement code for that as well. 

this script will be run with a keybind, so i dont want any output, no logging or no extra file creating. just clean. make sure the script is robust though. think long and hard before creating the script. 

now this is very important, i want you to make sure it does'nt apply the currently set wallpaper again ie not make any changes, when the script is run it shoudl check what the currently set wallpaper is and pick a wallpaper other than the currently set wallpaper. 

YOU CAN CHECK THAT BY running 
```bash
swww query
```
and you'll get an output somethign like this
the output will have a line like this example
obviously the currently_wallpaer.extention is a placeholder for the name of the wallpaper. 

```bash
: eDP-1: 1200x675, scale: 1.6, currently displaying: image: /home/dusk/.config/theming/all_themes/ember_glow/wallpaper/currently_wallpaer.extention
```