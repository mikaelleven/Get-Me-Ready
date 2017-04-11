ECHO "Installing power tools..."


REM ### Common Utilities ###
choco install sdelete

REM ### CONSOLE FIXES ###

REM Cygwin - Shell
choco install Cygwin

REM Console2 - Terminal
REM choco install Console2

REM Cmder
choco install cmder

REM ConsoleZ
choco install consolez

REM Command Promt Paste
choco install wincommandpaste


REM ### Console Tools ###

REM cURL
choco install curl



REM ### Disk utilities / USB & Flash drive tools ###
:: choco install win32diskimager.install
:: choco install rufus.install
:: choco install universal-usb-installer
start http://www.etcher.io/


REM ### General Tools ###
choco install windirstat
choco install sysinternals
choco install cpu-z
choco install gpu-z
:: choco install lockhunter REM LockHunter is a foolproof file unlocker
choco install ccenhancer 
::choco install Everything
::choco install powershell
choco install partitionwizard

REM Virtualization
choco install virtualbox
choco install vmwareplayer
choco install vagrant


