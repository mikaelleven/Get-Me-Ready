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


### Xamarin ###
brew cask install xamarin-jdk
brew cask install xamarin-android
brew cask install xamarin-android-player
brew cask install xamarin-ios
brew cask install xamarin-studio


### NativeScript ###

# iOS / XCode pre-req
sudo gem install xcodeproj
sudo gem install cocoapods

# Android / Java pre-req
brew cask install java
echo "export JAVA_HOME=\$(/usr/libexec/java_home)" >> ~/.bash_profile
brew install android-sdk
echo "export ANDROID_HOME=/usr/local/opt/android-sdk" >> ~/.bash_profile
android update sdk --filter tools,platform-tools,android-23,build-tools-23.0.3,extra-android-m2repository,extra-google-m2repository,extra-android-support --all --no-ui

# Install NativeScript
npm -g install nativescript


# IDE's and development editors
#brew cask install atom
#? apm install nuclide
#brew cask install --appdir="/Applications" pycharm
#brew cask install --appdir="/Applications" xamarin-studio
#?? brew cask install arduino

# Additional tools
#??brew install heroku
### .NET / Visual Studio for Mac ###
curl -s https://raw.githubusercontent.com/mikaelleven/Get-Me-Ready/master/Mac/GetMyApps/GMA_VisualStudio-Mac-Preview.sh | sh # Install 
brew install openssl
mkdir -p /usr/local/lib
ln -s /usr/local/opt/openssl/lib/libcrypto.1.0.0.dylib /usr/local/lib/
ln -s /usr/local/opt/openssl/lib/libssl.1.0.0.dylib /usr/local/lib/
#TODO: script to download & instal .NET Core https://www.microsoft.com/net/download/core#/sdk  https://go.microsoft.com/fwlink/?LinkID=835011
npm install -g generator-aspnet
npm install -g generator-aspnetcore
npm install -g generator-aspnetcore-angular2


### Visual Studio Code
source "$DIR/GetMyApps/GMA_VisualStudioCode.sh"



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