#!/bin/bash

echo "Preparing environment..."
echo 

echo "First we need to install some required software (XCode Tools). A new window will appear, proceed with that installation. When finished return to this terminal window."
echo 
read -p "Press any key when ready... " -n1 -s
echo  '\n'


# El Capitan Hombrew fix
sudo chown $(whoami):admin /usr/local && sudo chown -R $(whoami):admin /usr/local

# Install Homebrew
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

brew doctor
brew update
brew tap phinze/homebrew-cask
brew install brew-cask

# Prepare Homebrew Cask
brew cask

# Install Cask Upgrade ($ brew cu)
brew tap buo/cask-upgrade





