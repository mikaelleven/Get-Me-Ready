#!/bin/bash

echo -ne "Installing development applications, please wait..."

# Prepare script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


# General development tools:
brew install wget
#? brew install git
#? brew install git-flow

#brew cask install --appdir="/Applications" github
#curl -s http://www.getmacapps.com/raw/jz6rl | sh # GitHub
#brew cask install --appdir="/Applications" sourcetree
#curl -s http://www.getmacapps.com/raw/4zsox | sh # SourceTree

# NodeJS
source "$DIR/InstallNode.sh"

# NodeJS Components
npm -g install typescript


# Frameworks
#brew cask install mono-mdk
#brew cask install python
#brew cask install python3
#??brew cask install 


# Application/cross-platform Frameworks
brew cask install electron
#?   nativescript??


# IDE's and development editors
#brew cask install atom
#? apm install nuclide
#brew cask install --appdir="/Applications" pycharm
#brew cask install --appdir="/Applications" xamarin-studio
#?? brew cask install arduino

# Additional tools
#??brew install heroku





# Databases, cache and storage:
#brew cask install postgres
#brew cask install mongodb
#brew cask install rabbitmq
#brew cask install redis
#brew install memcached
#brew install elasticsearch


# Virtualization
brew cask install virtualbox
brew cask install vagrant
#?? vagrant init maier/alpine-3.3.1-x86_64 # Vagrant Alpine support
vagrant plugin install vagrant-alpine
#brew cask install --appdir="/Applications" vmware-fusion
#brew cask install otto
#:DOCKER-FOR-MAC:: brew cask install docker
#brew cask install docker-toolbox



### NODE SECTION ###

# Developer tools, automation etc
#npm install -g yo bower grunt-cli gulp # Yeoman

#npm install -g generator-keystone # KeystoneJS CMS




echo " done!"
echo