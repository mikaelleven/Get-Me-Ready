#!/bin/bash

echo -ne "Installing development applications, please wait..."

### Prepare script ###
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

### It is highly recommended to install XCode right away (it is a massive download)
open macappstore://itunes.apple.com/se/app/xcode/id497799835

### General development tools ###
brew install wget


### Git & source control ###
brew install git
brew install git-flow
brew cask install gitkraken
brew cask install github-desktop ##curl -s http://www.getmacapps.com/raw/jz6rl | sh # GitHub
brew cask install sourcetree ##curl -s http://www.getmacapps.com/raw/4zsox | sh # SourceTree


### Frameworks ###
#brew cask install mono-mdk
brew install python
brew install python3


### NodeJS ###
source "$DIR/InstallNode.sh"
npm install -g bower
npm install -g webpack
npm install -g yarn
npm install -g grunt-cli gulp
npm install -g yo
npm install -g generator-ng-fullstack
npm install -g generator-keystone


### TypeScript ###
npm install -g typescript
# npm install -g typings
# typings install dt~node --global --save
# typings install dt~express dt~serve-static dt~express-serve-static-core --global --save
# typings install dt~elasticsearch --global --save


### Application/cross-platform Frameworks ###
brew cask install electron
npm install --global yo generator-electron
#typings install dt~electron --global --save


### Xamarin ###
brew cask install xamarin-jdk
brew cask install xamarin-android
brew cask install xamarin-android-player
brew cask install xamarin-ios
brew cask install xamarin-studio


### NativeScript ###

# # iOS / XCode pre-req
# sudo gem install xcodeproj
# sudo gem install cocoapods

# # Android / Java pre-req
# brew cask install java
# echo "export JAVA_HOME=\$(/usr/libexec/java_home)" >> ~/.bash_profile
# brew install android-sdk
# echo "export ANDROID_HOME=/usr/local/opt/android-sdk" >> ~/.bash_profile
# android update sdk --filter tools,platform-tools,android-23,build-tools-23.0.3,extra-android-m2repository,extra-google-m2repository,extra-android-support --all --no-ui

# Install NativeScript
npm -g install nativescript
ruby -e "$(curl -fsSL https://www.nativescript.org/setup/mac)"



### .NET / Visual Studio for Mac ###
curl -s https://raw.githubusercontent.com/mikaelleven/Get-Me-Ready/master/Mac/GetMyApps/GMA_VisualStudio-Mac-Preview.sh | sh # Install 
npm install -g generator-aspnet
npm install -g generator-aspnetcore
npm install -g generator-aspnetcore-angular2


### Visual Studio Code
source "$DIR/GetMyApps/GMA_VisualStudioCode.sh"


### General IDE's and development editors ###
brew cask install atom
apm install nuclide
brew cask install pycharm


### Cloud tools ###
brew install heroku


### Databases, cache and storage ###
brew cask install postgres
brew cask install mongodb
brew cask install rabbitmq-app
brew cask install redis-app
brew install memcached
brew install elasticsearch


### Virtualization ###
brew cask install virtualbox
brew cask install vmware-fusion
#brew cask install parallels-desktop
brew cask install vagrant
vagrant plugin install vagrant-alpine # >> vagrant init maier/alpine-3.3.1-x86_64
vagrant plugin install vagrant-proxmox
vagrant plugin install vagrant-azure
brew cask install docker
brew cask install kitematic
#brew cask install docker-toolbox
#brew cask install otto


### Arduino / hardware development ###
brew cask install arduino
open 'https://tzapu.com/making-ch340-ch341-serial-adapters-work-under-el-capitan-os-x/' # CH340 fix for Mac OS X


echo " done!"
echo