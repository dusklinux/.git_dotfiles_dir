When the Hyper-V extensions are enabled, setting the useplatformclock option in bcdedit to "yes" results in poor performance. As a result, disable this feature.

Open the Terminal as an Administrator and type the following command, then press [Enter].

```powershell
C:\> bcdedit /set useplatformclock No
```