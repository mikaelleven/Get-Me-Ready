
REM Install Chocolatey (Package Manager)
@powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))" && SET PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin

choco install chocolateygui

REM Core applications
CALL Core.bat

REM Developer tools
::CALL Developer.bat

REM Productivity tools
::CALL Productivity.bat

REM PowerTools
::CALL PowerTools.bat

REM Additional fixes
::CALL Fix-CommandPrompt.bat









