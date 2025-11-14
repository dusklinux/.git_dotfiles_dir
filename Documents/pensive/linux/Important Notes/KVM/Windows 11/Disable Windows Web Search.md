When you search for something in the Windows Search box or Start menu, you may have to wait a few seconds as Windows retrieves your search results along with a list of suggested web results from Bing. Although this is a useful feature, you may dislike it and wish to disable it.

To disable web results on Windows 11, follow these steps:

    Enter regedit into the search box and press [Enter] to launch the Registry Editor.
    Browse to: Computer\HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows.
    Right-click the Windows key, select New, and then select the Key option. Enter Explorer as the key name and press [Enter].
    Now, right-click on the newly created Explorer key, select New, and then the DWORD (32-bit) Value option. Name the DWORD DisableSearchBoxSuggestions and press [Enter].
    Double-click the newly created DWORD DisableSearchBoxSuggestions and change its value from 0 to 1.
