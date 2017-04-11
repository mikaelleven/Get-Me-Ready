#!/bin/bash

echo "Installing power tools, please wait..."
echo 

# Note: We always honour Apple Store apps..


# System tools
brew cask install appcleaner
brew cask install smcfancontrol
brew cask install disk-inventory-x
brew cask install fluid

# Misc tools
brew cask install etcher


### FreeFileSync ###
brew cask install freefilesync
# -- 8.5 issue fix >>>>
if ! [ -e /Applications/FreeFileSync.app ] 
then
	echo "here"
	curl -L -A 'Mozilla/5.0 (X11; Linux x86_64; rv:30.0) Gecko/20100101 Firefox/30.0' -H 'Referer: http://www.freefilesync.org/archive.php' http://www.freefilesync.org/archive/FreeFileSync_8.4_Mac_OS_X.zip >> ~/Library/Caches/Homebrew/Cask/freefilesync--8.4.zip
	brew cask install freefilesync

	# If still not ok, let's open a browser to manully download
	if [ ! -e /Applications/FreeFileSync.app ] 
	then
		open "http://www.freefilesync.org/download.php"
	fi
fi
# -- 8.5 issue fix <<<<<<





