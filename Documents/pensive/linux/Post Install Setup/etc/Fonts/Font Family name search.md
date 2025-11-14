To use the new font in configuration files, you must know its exact "family name." The `fc-list` command helps you find this.

1.  **Find the Font Name**
    Use `fc-list` and pipe the output to `grep` to search for your newly installed font.

    ```bash
    fc-list | grep -i 'atkinson'
    ```
