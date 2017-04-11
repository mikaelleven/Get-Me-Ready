ECHO.
ECHO ### INSTALLING COMMON TOOLS... ###
ECHO.

REM ### Core Applications / Utilities ###

::choco install silverlight
::choco install flashplayerplugin


REM ### GENERAL TOOLS ###

:: Launchy launcher application
REM choco install launchy

:: f.lux
::choco install f.lux


REM Web Browsers
choco install googlechrome
::choco install GoogleChrome-AllUsers
choco install Firefox
REM choco install safari
choco install adblockplusie
choco install adblockplus-firefox
::choco install adblockpluschrome
start chrome "https://chrome.google.com/webstore/detail/ublock-origin/cjpalhdlnbpafiamejdnhcphjbkeiagm"


REM Media
::choco install spotify
::choco install vlc
::choco install cccp
::choco install handbrake.install



REM Other tools
::choco install lastpass
choco install autohotkey_l
REM choco install autohotkey.portable
::choco install teamviewer
::choco install FoxitReader
choco install filezilla

choco install paint.net



choco install ccleaner


REM ### Zip & Compression ###
choco install 7zip.install
REM choco install peazip.install

REM::choco install vcredist2010

# Ninite - PowerPack??
start https://ninite.com/


ECHO.
ECHO ### DONE INSTALLING COMMON TOOLS! ###
ECHO.


