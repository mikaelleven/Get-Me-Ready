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
	curl -L -A 'Mozilla/5.0 (X11; Linux x86_64; rv:30.0) Gecko/20100101 Firefox/30.0' -H 'Referer: https://www.freefilesync.org/archive.php' https://www.freefilesync.org/download/FreeFileSync_9.3_macOS.zip >> ~/Library/Caches/Homebrew/Cask/freefilesync--9.3.zip
	brew cask install freefilesync

	# If still not ok, let's open a browser to manully download
	if [ ! -e /Applications/FreeFileSync.app ] 
	then
		open "http://www.freefilesync.org/download.php"
	fi
fi
# -- 8.5 issue fix <<<<<<





