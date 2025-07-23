To use the new font in configuration files, you must know its exact "family name." The `fc-list` command helps you find this.

1.  **Find the Font Name**
    Use `fc-list` and pipe the output to `grep` to search for your newly installed font.

    ```bash
    fc-list | grep -i 'atkinson'
    ```

2.  **Interpret the Output**
    The command will list all matching font files and their properties. You are looking for the family name, which appears right after the file path.

You're looking for the FAMILY_NAME_1, which is the first thing after file path. 

(FILE_PATH): (FAMILY_NAME_1),(ALIAS_2),(ALIAS_3):style=(STYLE_DESCRIPTOR)

    **Example Output:**
    ```
    /usr/share/fonts/OTF/Atkinson-Hyperlegible-Regular-102.otf: Atkinson Hyperlegible:style=Regular
    /usr/share/fonts/OTF/Atkinson-Hyperlegible-Bold-102.otf: Atkinson Hyperlegible:style=Bold
    /usr/share/fonts/OTF/Atkinson-Hyperlegible-Italic-102.otf: Atkinson Hyperlegible:style=Italic
    ```
    In this case, the family name you need for your configuration is `Atkinson Hyperlegible`.
