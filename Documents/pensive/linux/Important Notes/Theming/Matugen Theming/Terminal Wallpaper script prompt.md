i want you to create a bash script that uses gum/nsxiv/rofi to display wallpapers in a user defined directory at the top of the script, and then when the wallpaper is chosen and selected, i want for it to run a command "matugen --mode light/dark image Pictures/wallpapers/image.name"

i want for the light or dark option to be decided by the user toggling an option with a keybind like "D" for dark and W for white. think long and hard before starting. and make sure you research extensively to get this right, this is for arch linux running hyprland. i want you to create the script as robust as possible so its fail proof and make sure you address as many edge cases as possible. while also not creating any extra logs or additional files, i want it to be clean. Think incredibly long and hard. 

make it auto adjust how many wallpapers are on in a row/ column depending on the size of the window, make it dynamic. like i said, think it all through.

also usee swww as the thing that changes the wallpaper, eg .swww img ~/Pictures/wallpapers/image.name --transition-type grow --transition-duration 2 --transition-fps 60
also allow for the variables in he --transition-type, transition duration and fps to be definable at the top of the scipt. so the user can change it later if he so desires.

the thing is, i want to see the wallpapers, like a preview of them so i can see them before picking one and selecting one like have them all preview it side by side in a gird, btw i'm using kitty as my terminal if that helps. btw doesn't have to be in the terminal, you could use rofi's dmenu to show the images if that works better

if gum is not needed then you don't have to use gum. btw once the user toggles dark mode or light mode, make sure it's universally applied as in it shouldnt ask the user over and over again if they user is switchign between wallpapers, dark/light mode should be togglable and then the script should run with what ever the user has set, and the user should be able to toggle back. also make sure the grid is interractive. to select and navigate around. 

or use fzf or nsxiv. which everone you think will work the best. 

don't create multiple scripts, only create one. 