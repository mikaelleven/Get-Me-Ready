#!/bin/bash

echo "Preparing environment..."
echo 


# Install Homebrew
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

brew doctor
brew update
brew tap phinze/homebrew-cask
brew install brew-cask


# Install Cask
#brew install caskroom/cask/brew-cask

# Prepare Homebrew Cask
brew cask



