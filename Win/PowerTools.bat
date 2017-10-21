ECHO "Installing power tools..."



REM ### MISC TOOLS ###
cinst curl
cinst openssh
::cinst MobaXTerm 
cinst putty
::cinst superputty



REM ### CONSOLE FIXES ###
cinst clink

cinst Cygwin

::cinst Console2
cinst cmder
::cinst consolez
::cinst babun

::cinst wincommandpaste


REM ### DISK & DRIVE UTILITIES ###
:: cinst win32diskimager.install
:: cinst rufus.install
:: cinst universal-usb-installer
cinst etcher
cinst freefilesync
cinst windirstat
cinst partitionwizard
cinst sdelete
:: cinst lockhunter REM LockHunter is a foolproof file unlocker


REM ### General Tools ###
cinst sysinternals
cinst cpu-z
cinst gpu-z
::cinst ccleaner
::cinst ccenhancer 
::cinst recuva
::cinst Everything
::cinst powershell


REM Virtualization
cinst virtualbox
cinst vmwareplayer
cinst vagrant




REM ### DO SOME INITIALIZATIONS ###
refreshenv
cmder.exe /register user

start http://projects.reficio.org/babun/download

