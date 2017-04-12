#!/bin/bash

clear
echo "==============================================="
echo "GetMeReady (Mac) v1.1 - Created by Mikael Levén"
echo "==============================================="
echo 

echo "First of all this script will install -Homebrew-."
echo

echo "Then following packages will be installed:"
echo "* Core (basic tools such as XtraFinder, Alfred, Hyperdock, Flux etc)"
echo "* Productivity (general productivity tools such as Evernote, Dropbox, Wunderlist, Slack etc)"
echo "* Development (developer specific tools such as WGet, Git, VirtualBox, MongoDB, NodeJS, Heroku Toolbelt)"
echo "* Core (XtraFinder, Alfred, Hyperdock, Flux)"
echo

echo "Finally some tweaks will be made:"
echo "* HotCorners (screensave/put screen to sleep)"
echo "* SublimeFix (Package Control, Themes, Command Line Tool, Custom Settings, copy license etc)"
echo "* Various general tweaks (Always show scrollbars, Finder-tweaks, DS_Store-fix etc)"
echo

read -p "Press any key to continue (or Ctrl + Z to abort)... " -n1 -s
echo  '\n'


clear
echo "==============================================="
echo "GetMeReady (mac) v1.1 - Created by Mikael Levén"
echo "==============================================="
echo 



DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
	
# echo "$DIR"

echo "Install all AppStore Apps at first!"

echo 
echo "Some suggestions:"
echo "Microsoft Remote Desktop"
echo "iWorks"
echo "Slack"
echo "Hamster Archiver"	
echo "iZip Viewer"
echo "Wünderlist"

# no solution to automate AppStore installs
echo
read -p "Press any key to continue... " -n1 -s
echo  '\n'

echo
echo "App Store: Completed"


echo
echo "Please provide your admin password to ensure as smooth progress as possible."

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until `.osx` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &


# Prepare the computer
source "$DIR/Prepare.sh"

# Install core applications
source "$DIR/Core.sh"

# Install productivity applications
source "$DIR/Productivity.sh"

# Install development applications
source "$DIR/Development.sh"

# Install nice-to-have applications
#source "$DIR/NiceToHave.sh"

# cleanup
brew cleanup --force
rm -f -r /Library/Caches/Homebrew/*
source "$DIR/Common.sh" # Install common applications

# Performs some tweaks
source "$DIR/HotCorners.sh" # Hot corners fix
source "$DIR/Tweaks.sh" # Generals OS tweaks
source "$DIR/SublimeFix.sh" # Run special commands for Sublime Text


# Fix other scripts that might be run individually later
chmod +x "$DIR/Core.sh"
chmod +x "$DIR/Common.sh"
chmod +x "$DIR/Productivity.sh"
chmod +x "$DIR/Development.sh"
chmod +x "$DIR/SublimeFix.sh"
chmod +x "$DIR/HotCorners.sh"
chmod +x "$DIR/Tweaks.sh"


echo 
echo "==============================================="
echo

echo "All applications installed, now please go ahead set your manual settings and install missing applications. Some suggestions:"
echo "Photoshop"
echo "iWork"
echo "7Zip"
echo ""
echo ""
echo ""


##TODO: finally open settings suggestions from blog etc
open "http://goo.gl/v8AiaA"


