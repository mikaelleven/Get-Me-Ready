#!/bin/bash

echo -ne "Installing development applications, please wait..."

# General development tools:
brew install wget
#brew cask install --appdir="/Applications" github
curl -s http://www.getmacapps.com/raw/jz6rl | sh # GitHub
#brew cask install --appdir="/Applications" sourcetree
curl -s http://www.getmacapps.com/raw/4zsox | sh # SourceTree




# Optional tools:
brew cask install --appdir="/Applications" atom
#brew cask install --appdir="/Applications" pycharm
#brew cask install heroku-toolbelt
#brew cask install node
brew cask install mono-mdk
brew cask install --appdir="/Applications" xamarin-studio


# Databases, cache and storage:
#brew cask install postgres
#brew cask install mongodb
#brew install rabbit
#brew install redis
#brew install memcached


# Virtualization
brew cask install vagrant
#brew cask install --appdir="/Applications" vmware-fusion
brew cask install virtualbox
#>> OTTO
#>> DOCKER


### NODE SECTION ###

# Developer tools, automation etc
#npm install -g yo bower grunt-cli gulp # Yeoman

#npm install -g generator-keystone # KeystoneJS CMS




echo " done!"
echo