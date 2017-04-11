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
brew cask install flux ##curl -s http://www.getmacapps.com/raw/13ydj5 | sh # f.lux

# Avast Antivirus & Security
brew cask install avast

# Hyperdock
brew cask install hyperdock
#brew cask install bettertouchtool

# (optional) White clock (if you prefer dark theme)
#OLD: brew cask install whiteclock

# Other system tools
brew cask install iterm2 ##curl -s http://www.getmacapps.com/raw/18y69 | sh # iterm2
#brew cask install caffeine ##curl -s http://www.getmacapps.com/raw/5m9t | sh # Caffeine
#brew cask install karabiner
brew cask install the-unarchiver # The Unarchiver
brew cask install itsycal # Itsycal


# Web browsers
brew cask install google-chrome ##curl -s http://www.getmacapps.com/raw/3 | sh # Chrome
brew cask install firefox ##curl -s http://www.getmacapps.com/raw/9 | sh # FireFox
#brew cask install opera-next

# General purpose applications

brew cask install flash
brew cask install java
brew cask install teamviewer
brew cask install filezilla ##curl -s http://www.getmacapps.com/raw/9zldt | sh # FileZilla
brew cask install spotify ##curl -s http://www.getmacapps.com/raw/1t | sh # Spotify
brew cask install vlc ##curl -s http://www.getmacapps.com/raw/3l | sh # VLC Player

#brew cask install crashplan
#brew cask install cord
#brew cask install little-snitch
#brew cask install transmit

## Sublime Text special
brew tap caskroom/versions # Needed for ST3
brew cask install sublime-text3 # ST3 ##curl -s http://www.getmacapps.com/raw/b8jl | sh


# Open installed applications
open /Applications/Flux.app
open /Applications/Dropbox.app
open /Applications/XtraFinder.app

# AdBlock / uBlock Origin
open -a Firefox 'https://adblockplus.org/en/firefox'
open -a Safari 'https://adblockplus.org/en/safari'
#open -a 'Google Chrome' 'https://adblockplus.org/en/chrome'
open -a "Google Chrome" https://chrome.google.com/webstore/detail/ublock-origin/cjpalhdlnbpafiamejdnhcphjbkeiagm


# Script & aliases
echo "alias flushdns='dscacheutil -flushcache && sudo killall -HUP mDNSResponder'" >> ~/.bash_profile
echo "alias brew-update='brew update && brew upgrade && brew cu && brew cleanup'" >> ~/.bash_profile
echo "alias cd..='cd ..'" >> ~/.bash_profile