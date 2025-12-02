### **The "Modern Shell" Core (Zsh + Rust Rewrites)**

_These replace legacy GNU utils with faster, prettier, and more functional alternatives._

1. **Starship** (`starship`): The minimal, blazing-fast, and infinitely customizable prompt.
    
2. **Zoxide** (`zoxide`): A smarter `cd` that remembers your most used paths.
    
3. **FZF** (`fzf`): The fuzzy finder. Mandatory for reverse-search history and file opening.
    
4. **Eza** (`eza`): A modern, maintained replacement for `ls` (fork of `exa`) with Git integration.
    
5. **Bat** (`bat`): A `cat` clone with syntax highlighting and Git integration.
    
6. **Ripgrep** (`ripgrep`): `grep`, but faster and respects `.gitignore`.
    
7. **Fd** (`fd`): A user-friendly, faster alternative to `find`.
    
8. **Procs** (`procs`): A modern replacement for `ps` with colored output and human-readable columns.
    
9. **Tokei** (`tokei`): Displays statistics about your code (LOC, comments, etc.).
    
10. **Hyperfine** (`hyperfine`): A command-line benchmarking tool.
    
11. **Tealdeer** (`tealdeer`): A fast implementation of `tldr` (simplified man pages).
    
12. **Vivid** (`vivid`): A generator for `LS_COLORS` with true-color support.
    
13. **Dust** (`dust`): A more intuitive `du` (disk usage) written in Rust.
    
14. **Duf** (`duf`): A better `df` (disk free) with a clear tabular layout.
    
15. **Zellij** (`zellij`): A terminal workspace/multiplexer (modern `tmux` alternative).
    
16. **Atuin** (`atuin`): Sync, search, and backup shell history across machines.
    
17. **Direnv** (`direnv`): Unclutter your `.zshrc`; load env vars automatically per directory.
    
18. **Entr** (`entr`): Run arbitrary commands when files change (excellent for dev loops).
    
19. **Just** (`just`): A handy command runner (like `make`, but for tasks).
    
20. **Trash-cli** (`trash-cli`): Use the trash can instead of `rm` forever.
    

---

### **II. System & Container Monitoring**

_Visualizing system state, vital for architecture and debugging._

21. **Btop** (`btop`): The king of system monitors. Beautiful, responsive, mouse support.
    
22. **Htop** (`htop`): The classic standard.
    
23. **Nvtop** (`nvtop`): GPU process monitoring (essential for local LLMs/AI).
    
24. **Bottom** (`bottom`): A cross-platform graphical process/system monitor.
    
25. **Glances** (`glances`): "Eye on your system." Can run in client/server mode.
    
26. **K9s** (`k9s`): The ultimate TUI for managing Kubernetes clusters.
    
27. **Lazydocker** (`lazydocker`): A simple terminal UI for Docker and Docker Compose.
    
28. **Ctop** (`ctop`): Top-like interface for container metrics.
    
29. **Dry** (`dry-bin`): A Docker manager that mimics `docker ps` but interactive.
    
30. **Sen** (`sen`): Terminal interface for docker engine.
    
31. **Bandwhich** (`bandwhich`): Terminal bandwidth utilization tool (shows process usage).
    
32. **Trippy** (`trippy`): A network diagnostic tool (better `traceroute`).
    
33. **Gping** (`gping`): Ping, but with a graph.
    
34. **Zenith** (`zenith`): Like top, but with zoomable history charts.
    
35. **Gotop** (`gotop`): Graphical activity monitor.
    

---

### **III. File Management & Navigation**

_For when `cd` and `ls` aren't enough._

36. **Yazi** (`yazi`): **Top Pick.** Blazing fast, async, Rust-based. **Supports Kitty graphics protocol** for high-res image previews.
    
37. **Ranger** (`ranger`): The classic Vim-like file manager. Python-based.
    
38. **Nnn** (`nnn`): Extremely lightweight, fast, and scriptable.
    
39. **Lf** (`lf`): A ranger alternative written in Go (faster startup).
    
40. **Broot** (`broot`): An interactive tree view; great for navigating deep nested folders.
    
41. **Xplr** (`xplr`): A hackable, JSON-configured file explorer.
    
42. **Vifm** (`vifm`): If you want your file manager to behave exactly like Vim.
    
43. **Clifm** (`clifm`): A CLI-based file manager (shell-like), very unique.
    
44. **Midnight Commander** (`mc`): The orthodox dual-pane ancestor. Reliable.
    
45. **Superfile** (`superfile-bin`): A very "fancy" modern TUI file manager.
    

---

### **IV. Development & Git Workflow**

_Streamline your coding and version control._

46. **Lazygit** (`lazygit`): The best Git TUI. Makes complex rebases/staging trivial.
    
47. **Tig** (`tig`): Text-mode interface for Git. Great for browsing commit history.
    
48. **GitUI** (`gitui`): Blazing fast Git client in Rust.
    
49. **Gh-dash** (`gh-dash`): A GitHub dashboard in your terminal (PRs, issues).
    
50. **Git-delta** (`git-delta`): A syntax-highlighting pager for git, diff, and grep output.
    
51. **Onefetch** (`onefetch`): Neofetch, but for Git repositories (code stats).
    
52. **Aichat** (`aichat`): CLI for using LLMs (OpenAI, Claude, Local) in the terminal.
    
53. **Shellcheck** (`shellcheck`): Static analysis for shell scripts (crucial for you).
    
54. **Pre-commit** (`pre-commit`): Manage multi-language pre-commit hooks.
    
55. **Act** (`act`): Run GitHub Actions locally.
    

---

### **V. Text Editors, Viewers & Data**

_Viewing and editing data without leaving the terminal._

56. **Helix** (`helix`): A post-modern modal text editor (Kakoune/Neovim inspired).
    
57. **Neovim** (`neovim`): The hyperextensible Vim-based text editor.
    
58. **Glow** (`glow`): Render Markdown on the CLI with pizzazz.
    
59. **Presenterm** (`presenterm`): Run presentation slides in the terminal (Kitty graphics support).
    
60. **Slides** (`slides`): Another great markdown presentation tool.
    
61. **Visidata** (`visidata`): A "spreadsheet" for the terminal. Incredible for CSV/JSON/SQL analysis.
    
62. **Fx** (`fx`): Interactive JSON viewer and processor.
    
63. **Jless** (`jless`): A pager for JSON data.
    
64. **Hexyl** (`hexyl`): A command-line hex viewer.
    
65. **Imhex** (`imhex-bin`): (Technically GUI but often has CLI modes/TUI feel) Hex editor.
    
66. **Chafa** (`chafa`): Terminal graphics for the 21st century (view images as text/sixel/kitty).
    
67. **Timg** (`timg`): A terminal image viewer (supports Kitty graphics).
    
68. **Dadbod-ui** (Vim plugin): If you use Nvim, this is the best TUI database client.
    
69. **Lazysql** (`lazysql`): A cross-platform TUI database management tool.
    
70. **Usgs** (`usql`): Universal command-line interface for SQL databases.
    

---

### **VI. Network, Web & Communication**

_The internet, but text-only._

71. **Httpie** (`httpie`): A user-friendly `curl` replacement.
    
72. **Curlie** (`curlie`): The power of `curl` with the ease of `httpie`.
    
73. **Doggo** (`doggo`): A modern command-line DNS client (dig replacement).
    
74. **Termshark** (`termshark`): A TUI for Wireshark (packet analysis).
    
75. **Newsboat** (`newsboat`): An RSS/Atom feed reader.
    
76. **Weechat** (`weechat`): The extensible chat client (IRC, Matrix, Slack).
    
77. **Aerc** (`aerc`): An email client for hackers (Vim-style).
    
78. **Neomutt** (`neomutt`): The classic command-line mail reader.
    
79. **W3m** (`w3m`): Text-based web browser (supports images in some terms).
    
80. **Lynx** (`lynx`): The oldest web browser still in use.
    
81. **Posting** (`posting`): A powerful HTTP/API client (like Postman) TUI.
    

---

### **VII. Productivity & Organization**

_Stay organized without a GUI._

82. **Taskwarrior-tui** (`taskwarrior-tui`): A TUI wrapper for the legendary Taskwarrior.
    
83. **Timewarrior** (`timewarrior`): Track time from the CLI.
    
84. **Calcurse** (`calcurse`): A text-based calendar and scheduling application.
    
85. **Khal** (`khal`): CLI calendar application built with Python.
    
86. **Pass** (`pass`): The standard unix password manager.
    
87. **Gopass** (`gopass`): The "slightly more modern" pass alternative in Go.
    
88. **Nb** (`nb`): CLI note-taking, bookmarking, and archiving.
    
89. **Zk** (`zk`): A plain text note-taking assistant (Zettelkasten).
    
90. **Speedtest-cli** (`speedtest-cli`): Check internet speed.
    

---

### **VIII. Fun, Customization & "Rice"**

_Because a terminal should look cool._

91. **Cava** (`cava`): Console-based Audio Visualizer for ALSA/Pulse/Pipewire.
    
92. **Pipes.sh** (`pipes.sh`): Animated pipes terminal screensaver.
    
93. **Cbonsai** (`cbonsai`): Grow a bonsai tree in your terminal.
    
94. **Neofetch** (or **Fastfetch** `fastfetch`): System info script (Fastfetch is the modern C replacement).
    
95. **Cmatrix** (`cmatrix`): The Matrix screen effect.
    
96. **Figlet** (`figlet`): Large ASCII text banners.
    
97. **Toilet** (`toilet`): Colorful large ASCII text.
    
98. **Spotify-tui** (`spotify-tui`): A Spotify client for the terminal.
    
99. **Ncspot** (`ncspot`): Another great ncurses Spotify client.
    
100. **Moc** (`moc`): Music On Console - a lightweight music player.