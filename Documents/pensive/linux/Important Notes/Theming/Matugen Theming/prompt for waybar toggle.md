Create a bash script for arch linux running hyprland that switches between dark/light mode. There are several components to this. I want you to have the script do the following

i want you to help me configure a toggle that allows for switching dark/light mode. it's on hyprland arch linux, I want it so that when i toggle it it should replace the word dark with light or light with dark in this file for the post command - 
"[Settings]
language = en
folder = ~/Pictures/wallpapers
monitors = All
wallpaper = ~/Pictures/wallpapers/GKusPIEWkAAZAgg.jpg
show_path_in_tooltip = True
backend = swww
fill = fill
sort = name
color = #ffffff
subfolders = False
all_subfolders = False
show_hidden = False
show_gifs_only = False
zen_mode = False
post_command = matugen --mode light image $wallpaper
number_of_columns = 3
swww_transition_type = any
swww_transition_step = 63
swww_transition_angle = 0
swww_transition_duration = 2
swww_transition_fps = 60
mpvpaper_sound = False
mpvpaper_options = 
use_xdg_state = False
stylesheet = /home/dusk/.config/waypaper/style.css
"
it's location is $HOME/.config/waypaper/config.ini 


- after you switch that, also make sure to also run the command to change the theme for that wallpaper eg if the script toggled to light mode. - matugen --mode light image Pictures/wallpapers/13p96y7g7xn41.jpg
  
  and if it's toggeled to dark mode matugen --mode dark image Pictures/wallpapers/13p96y7g7xn41.jpg
  
and oh,   i want you to get the current wallpaper that is already set and insert that in the path to the image's place for the commands above. 
  
  
  There's another existing script i have that i also want you to change teh light/dark mode for and that is placed in $HOME/user_scripts/swww/swww_random_standalone.sh
i want you to edit the variable in it that is on a line with this text 
eg: if it's dark it'll be 
"readonly theme_mode="dark" # <-- SET THIS"
if its light it'll be 
"readonly theme_mode="light" # <-- SET THIS"

but make sure that both files have been changed to the same thing not that one file has light mode and the other dark mode. both need to be set to the same thing, so if you changed the waypaper's config to light, also change the script's variable to light, regardless of what it's at already. 

think long and hard and make sure you research this extensively 
