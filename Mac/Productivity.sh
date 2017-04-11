#!/bin/bash

echo "Installing productivity applications, please wait..."
echo 

# Note: We always honour Apple Store apps..

# Communication
brew cask install google-hangouts
brew cask install slack
brew cask install franz
brew cask install skype ##curl -s http://www.getmacapps.com/raw/sh | sh # Skype


# General productivity tools
brew cask install omnigraffle
brew cask install dropbox ##curl -s http://www.getmacapps.com/raw/6bl | sh # dropbox
brew cask install google-drive ##curl -s http://www.getmacapps.com/raw/pa9 | sh # Google Drive
brew cask install skydrive
brew cask install xmind


# Notes, lists and such
brew cask install lastpass
brew cask install evernote ##curl -s http://getmacapps.com/raw/m672jxbim9 | sh # Evernote
brew cask install skitch ## curl -s http://getmacapps.com/raw/b33j9ynrb5 | sh # Skitch
#DOES NOT WORKbrew cask install --appdir="/Applications" wunderlist
#brew cask install trello-x # Trello


# Office
#brew cask install microsoft-office # Office 2016 (v15)
brew cask install caskroom/versions/microsoft-office-2011

