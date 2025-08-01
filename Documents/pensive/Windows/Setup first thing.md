install
pnputil /add-driver B:\"Drivers 10 mar 2025"\*.inf /subdirs /install

export
pnputil /export-driver * B:\Drivers


iwr -useb https://christitus.com/win | iex


PERFECT WAY TO COMPRESS WINDOWS , uses a very efficiant algorithm and only targets system files that are compressible. this is a native feature
compact /compactos:always


refs version
fsutil fsinfo refsinfo <driveletter>



change boot name

bcdedit /set {current} description "Shutdown"




Microsoft Store

LTSC editions do not come with store apps pre-installed. To install them, follow the steps below.

    Make sure the Internet is connected.
    Open Powershell as admin and enter,
    wsreset -i
    Wait for a notification to appear that the store app is installed, it may take a few minutes.

On Windows 10 2021 LTSC, you might encounter an error indicating that cliprenew.exe cannot be found. This error can be safely ignored.

App Installer

This app is very useful; it includes WinGet, enabling easy installation of .appx packages. After installing the Store app, install the App installer from this URL.

https://apps.microsoft.com/detail/9nblggh4nns1


CLEAN INSTALL DRIVER EXTRACTION STEPS:

FIRST BREAFLY CONNECT TO THE INTERNET TO ACTIVATE WINDOWS AUTOMATIACLLY. (GENIUINE)
THEN TURN OFF WIFI. QUICKLY AFTER
open oo shuthup and disable all updates, 
install cloudflair warp
restart
maniual update through windows mini update tool (first os update then restart and then drivers)
install armoury crate fully (don't install ms store befroe installing armoury crate)
THEN install ms store
myasus
all the media codecs and extensions form teh microsoft store.
install snappy driver origin drivers/updates
chris titus script to clean all the leftovver resudeual updates.
export drivers
