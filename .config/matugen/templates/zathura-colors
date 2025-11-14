" -----------------------------------------------------------------------------
" Zathura settings
" -----------------------------------------------------------------------------

" Colors
set default-bg              "{{colors.on_primary.default.rgba | set_alpha: 1.0}}"
set default-fg              "{{colors.primary.default.hex}}"

set statusbar-bg            "{{colors.on_primary.default.hex}}"
set statusbar-fg            "{{colors.primary.default.hex}}"

set inputbar-bg             "{{colors.on_primary.default.hex}}"
set inputbar-fg             "{{colors.primary.default.hex}}"

set notification-error-bg   "{{colors.on_error.default.hex}}"
set notification-error-fg   "{{colors.error.default.hex}}"

set notification-warning-bg "{{colors.primary_fixed.default.hex}}"
set notification-warning-fg "{{colors.error_container.default.hex}}"

set highlight-color         "{{colors.primary_fixed.default.hex}}"
set highlight-active-color  "{{colors.primary_fixed_dim.default.hex}}"

set completion-highlight-fg "{{colors.on_primary.default.hex}}"
set completion-highlight-bg {{colors.primary.default.hex}}""

set completion-bg           "{{colors.on_primary.default.hex}}"
set completion-fg           "{{colors.primary.default.hex}}"

set notification-bg         "{{colors.on_primary.default.hex}}"
set notification-fg         "{{colors.primary.default.hex}}"

set recolor                 "true"
set recolor-lightcolor      "{{colors.on_primary.default.rgba | set_alpha: 1.0}}"
set recolor-darkcolor       "{{colors.primary.default.hex}}"
set recolor-reverse-video   "true"
set recolor-keephue         "true"

" Clipboard
set selection-clipboard clipboard

" Search
set incremental-search true
set search-hadjust true

" Autoadjust
set adjust-open width

" Typography
set font "FiraCode Nerd Font 12"

" -----------------------------------------------------------------------------
" Zathura mappings
" -----------------------------------------------------------------------------
" remove status bar
set guioptions none
" Zoom in/out
map [normal]     z zoom in
map [normal]     Z zoom out
map [fullscreen] z zoom in
map [fullscreen] Z zoom out

" Toggle mode
map [normal]     D toggle_page_mode
map [fullscreen] D toggle_page_mode

" Scroll
map [normal]     u scroll half-up
map [normal]     d scroll half-down
map [fullscreen] u scroll half-up
map [fullscreen] d scroll half-down

" Fullscreen
map [normal]     f toggle_fullscreen
map [fullscreen] f toggle_fullscreen

" Reload
map [normal]     <C-r> reload
map [fullscreen] <C-r> reload

" Status bar
map [normal]     b toggle_statusbar
map [fullscreen] b toggle_statusbar

" Set width as in mupdf
map [normal]     H adjust_window best-fit
map [normal]     W adjust_window width
map [fullscreen] H adjust_window best-fit
map [fullscreen] W adjust_window width

map [normal]     i set recolor
map [fullscreen] i set recolor
