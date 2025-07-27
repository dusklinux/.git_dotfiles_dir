## The defualt setup is already *great*. So this is is optional. 

Starship is configured via a TOML file located at `~/.config/starship.toml`. You will likely need to create this file yourself.


1.  **Create the configuration file:**
    ```bash
    mkdir -p ~/.config && touch ~/.config/starship.toml
    ```

2.  **Add your configuration.** You can start with a simple configuration or explore the vast number of options on the [Starship website](https://starship.rs/config/).

    Here is a simple example to get you started. Paste this into your `~/.config/starship.toml` file:

    ```toml
    # ~/.config/starship.toml

    # Inserts a blank line between shell prompts
    add_newline = true

    # Change the default prompt format
    format = """
    [](#9A348E)\
    $os\
    $username\
    [](bg:#DA627D fg:#9A348E)\
    $directory\
    [](bg:#FCA17D fg:#DA627D)\
    $git_branch\
    $git_status\
    [](bg:#86BBD8 fg:#FCA17D)\
    $c\
    $elixir\
    $elm\
    $golang\
    $haskell\
    $java\
    $julia\
    $nodejs\
    $nim\
    $rust\
    $python\
    [](bg:#06969A fg:#86BBD8)\
    $docker_context\
    [](fg:#06969A)\
    \n$character"""

    [directory]
    style = "bg:#DA627D"
    format = "[ $path ]($style)"
    truncation_length = 3
    truncation_symbol = "…/"

    [git_branch]
    symbol = ""
    style = "bg:#FCA17D"
    format = "[ $symbol $branch ]($style)"

    [git_status]
    style = "bg:#FCA17D"
    format = "[($all_status$ahead_behind )]($style)"

    # ... and so on for other modules
    ```
