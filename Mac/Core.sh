#!/bin/bash

echo "Installing core applications, please wait..."
echo 

# Note: first we install OS X tweak utilities, those are specifically named to be easy to spot (if you want to disable them)

# Xtra Finder
brew cask install xtrafinder


# Alfred (run or install)
if [ -e /Applications/Alfred\ 2.app ]
then
	open /Applications/Alfred\ 2.app
else
	if [ -e /Applications/Alfred.app ]
	then
		open /Applications/Alfred.app
	else
		curl -s http://www.getmacapps.com/raw/1k4fnc6pt | sh # Alfred
		open /Applications/Alfred\ 2.app
	fi	
fi

echo 
read -p "Please start Alfred (or make sure it’s running) and then press any key when Alfred is running... " -n1 -s
echo  '\n'

# Prepare Alfred for Homebrew Cask (link Cask Apps to Alfred)
brew cask alfred link

# f.lux
#brew cask install flux
#curl -s http://www.getmacapps.com/raw/13ydj5 | sh # f.lux

# Hyperdock
brew cask install hyperdock
#brew cask install --appdir="/Applications" hyperdock
#brew cask install bettertouchtool

# (optional) White clock (if you prefer dark theme)
#brew cask install whiteclock

# Other system tools
#brew cask install iterm2
#curl -s http://www.getmacapps.com/raw/18y69 | sh # iterm2
#brew cask install caffeine
#curl -s http://www.getmacapps.com/raw/5m9t | sh # Caffeine
brew cask install smcfancontrol
#brew cask install karabiner
brew cask install the-unarchiver # The Unarchiver
brew cask install itsycal # Itsycal


# Web browsers
#brew cask install --appdir="/Applications" google-chrome
#curl -s http://www.getmacapps.com/raw/3 | sh # Chrome
#brew cask install --appdir="/Applications" firefox
#curl -s http://www.getmacapps.com/raw/9 | sh # FireFox
#brew cask install --appdir="/Applications" opera-next


# General purpose applications

brew cask install flash
#OLD, bad?: brew cask install --appdir="~/Applications" java
brew install Caskroom/cask/java
brew cask install --appdir="~/Applications" teamviewer
#brew cask install --appdir="~/Applications" filezilla
#curl -s http://www.getmacapps.com/raw/9zldt | sh # FileZilla
#brew cask install --appdir="/Applications" spotify
#curl -s http://www.getmacapps.com/raw/1t | sh # Spotify
#brew cask install --appdir="~/Applications" vlc
#curl -s http://www.getmacapps.com/raw/3l | sh # VLC Player

#brew cask install crashplan 
#brew cask install --appdir="~/Applications" cord
#brew cask install --appdir="/Applications" little-snitch
#brew cask install --appdir="~/Applications" transmit

## Sublime Text special
#brew tap caskroom/versions # Needed for ST3
#brew cask install --appdir="/Applications" sublime-text3 # ST3
#curl -s http://www.getmacapps.com/raw/b8jl | sh
##brew cask install --appdir="/Applications" sublime-text # ST2


# Open installed applications
#open /Applications/Flux.app
#open /Applications/Dropbox.app
#open /Applications/XtraFinder.app

# AdBlock
#open -a Firefox 'https://adblockplus.org/en/firefox'
#open -a 'Google Chrome' 'https://adblockplus.org/en/chrome'
#open -a Safari 'https://adblockplus.org/en/safari'
