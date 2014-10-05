#!/bin/bash

echo "Installing productivity applications, please wait..."
echo 

# Note: We always honour Apple Store apps..

# Communication
brew cask install --appdir="/Applications" google-hangouts
#NO SLACK:: brew cask install slack
#brew cask install --appdir="/Applications" skype
curl -s http://getmacapps.com/raw/sh | sh # Skype


# General productivity tools
brew cask install --appdir="/Applications" omnigraffle
#brew cask install --appdir="/Applications" dropbox
curl -s http://getmacapps.com/raw/6bl | sh # dropbox
#brew cask install --appdir="/Applications" google-drive
curl -s http://getmacapps.com/raw/pa9 | sh # Google Drive
#brew cask install --appdir="/Applications" skydrive


# Notes, lists and such
brew cask install --appdir="/Applications" lastpass-universal
##brew cask install --appdir="/Applications" evernote
#NO EVERNOTE:: curl -s http://getmacapps.com/raw/m672jxbim9 | sh # Evernote
##brew cask install --appdir="/Applications" skitch
#NO SKITCH:: curl -s http://getmacapps.com/raw/b33j9ynrb5 | sh # Skitch
#DOES NOT WORKbrew cask install --appdir="/Applications" wunderlist