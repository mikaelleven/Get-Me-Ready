ECHO "Installing developer tools..."


REM ### LANGUAGES / FRAMEWORKS ###
REM choco install ruby
REM choco install python
REM  choco install python3
REM choco install php

REM NodeJS
choco install nodejs.install
choco install nodist
::start "https://github.com/coreybutler/nvm-windows#node-version-manager-nvm-for-windows"


REM ### APPLICATION FRAMEWORKS	###
choco install electron

REM ### DATABASES / STORES / CACHE ###

REM choco install rabbitmq
REM choco install redis
REM choco install redis-64
REM choco install memcached

REM Databases
choco install mongodb
choco install postgresql

REM SQLite
choco install SQLite
choco install sqliteadmin
REM choco install sqlitebrowser

REM SQL Server
choco install mssql2014express-defaultinstance
choco install mssqlservermanagementstudio2014express
REM choco install sqlserverlocaldb
REM choco install MsSqlServer2012Express


REM ### DEVELOPER TOOLS ###

choco install webpi
choco install ilmerge
REM choco install fiddler
choco install fiddler4
choco install dotPeek

REM IDEs / Editors
choco install visualstudiocode
::choco install visualstudio2015enterprise
::choco install visualstudio2015professional
::choco install visualstudio2015community


REM Git clients
choco install sourcetree
choco install github
::choco install githubforwindows
choco install gitkraken
choco install kdiff3


REM Cloud services
::choco install awstools.powershell
::choco install awscli
::choco install windowsazurepowershell


>> choco install VisualStudio2013Ultimate
cinst VisualStudio2013Ultimate -InstallArguments "/Features:'WebTools Win8SDK' /ProductKey:AB1CD-EF2GH-IJ3KL-MN4OP-QR5ST"
You simply need to send a white space delimited list of the features to install via the InstallArguments parameter. Here are the available features:
Blend
LightSwitch
VC_MFC_Libraries
OfficeDeveloperTools
SQL
WebTools
Win8SDK
SilverLight_Developer_Kit
WindowsPhone80
>>>>>>>>
