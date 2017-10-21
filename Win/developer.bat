

ECHO "Installing developer tools..."


REM ### LANGUAGES / FRAMEWORKS ###
cinst DotNet4.5.2
cinst DotNet4.6.1
::cinst DotNet4.7

cinst dotnetcore
cinst dotnetcore-sdk

::cinst ruby
cinst python REM python3
::cinst python3
cinst python2
::cinst pip
::cinst php

REM ### NodeJS ###
::cinst nodejs.install
::cinst nodist
cinst nvm
nvm install latest


REM ### APPLICATION FRAMEWORKS	###
cinst electron

REM ### DATABASES / STORES / CACHE ###
::cinst rabbitmq
::cinst redis
::cinst redis-64
::cinst memcached
::cinst mongodb
::cinst postgresql

REM SQLite
::cinst SQLite
::cinst sqliteadmin
::cinst sqlitebrowser

REM SQL Server
cinst MsSqlServer2014Express
::cinst mssql2014express-defaultinstance
cinst mssqlservermanagementstudio2014express
::cinst sqlserverlocaldb
::cinst MsSqlServer2012Express


REM ### IDE:S / EDITORS ###
::cinst visualstudio2015enterprise
::cinst visualstudio2015professional
::cinst visualstudio2015community
cinst VisualStudio2017Community
::cinst VisualStudio2017Professional
cinst visualstudiocode


REM ### TOOLS ###
cinst webpi
cinst ilmerge
::cinst fiddler
cinst fiddler4
cinst dotPeek
cinst kdiff3
cinst nuget.commandline


REM ### SOURCE CONTROL ###
cinst sourcetree
cinst github
::cinst githubforwindows
cinst gitkraken


REM ### CLOUD SERVICES ###
::cinst awstools.powershell
::cinst awscli
cinst WindowsAzurePowerShell


rem >> cinst VisualStudio2013Ultimate
rem cinst VisualStudio2013Ultimate -InstallArguments "/Features:'WebTools Win8SDK' /ProductKey:AB1CD-EF2GH-IJ3KL-MN4OP-QR5ST"
rem You simply need to send a white space delimited list of the features to install via the InstallArguments parameter. Here are the available features:
rem Blend
rem LightSwitch
rem VC_MFC_Libraries
rem OfficeDeveloperTools
rem SQL
rem WebTools
rem Win8SDK
rem SilverLight_Developer_Kit
rem WindowsPhone80
rem >>>>>>>>
