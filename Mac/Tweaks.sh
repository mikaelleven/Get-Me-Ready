#!/bin/bash

echo "Tweaking your OS, please wait..."
echo 

###############################################################################
# General
###############################################################################


echo "Expanding the save panel by default"
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true


echo ""
echo "Enabling full keyboard access for all controls (e.g. enable Tab in modal dialogs)"
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3


# echo ""
#echo "Turn off keyboard illumination when computer is not used for 5 minutes"
# defaults write com.apple.BezelServices kDimTime -int 300


echo ""
echo "Always show scroll bars"
defaults write NSGlobalDomain AppleShowScrollBars -string "Always"


echo ""
echo "Use current directory as default search scope in Finder"
#if ask "Use current directory as default search scope in Finder" Y; then
  defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
#fi


# echo ""
# echo "Enable AirDrop over Ethernet and on unsupported Macs running Lion"
# defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true


echo ""
echo "Enable tap to click on Trackpad and login screen"
#if ask "Enable tap to click on Trackpad and login screen" Y; then
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write com.apple.mouse.tapBehaviour -int 1
#fi




###############################################################################
# Web Browsers
###############################################################################

# echo ""
# echo "Disable annoying backswipe in Chrome"
# defaults write com.google.Chrome AppleEnableSwipeNavigateWithScrolls -bool false



###############################################################################
# Screen
###############################################################################
 
# echo ""
# echo "Requiring password immediately after sleep or screen saver begins"
# defaults write com.apple.screensaver askForPassword -int 1
# defaults write com.apple.screensaver askForPasswordDelay -int 0
 
# echo ""
# echo "Setting screenshot format to PNG"
# defaults write com.apple.screencapture type -string "png"

# echo ""
# echo "Enabling subpixel font rendering on non-Apple LCDs"
# defaults write NSGlobalDomain AppleFontSmoothing -int 2
 
# echo ""
# echo "Enabling HiDPI display modes (requires restart)"
# sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true
 



###############################################################################
# Finder
###############################################################################
 
# echo ""
# echo "Showing icons for hard drives, servers, and removable media on the desktop"
# defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
 
# echo ""
# echo "Show hidden files in Finder by default?"
# select yn in "Yes" "No"; do
#   case $yn in
#     Yes ) defaults write com.apple.Finder AppleShowAllFiles -bool true
#         break;;
#     No ) break;;
#   esac
# done
 
# echo ""
# echo "Show dotfiles in Finder by default?"
# select yn in "Yes" "No"; do
#   case $yn in
#     Yes ) defaults write com.apple.finder AppleShowAllFiles TRUE
#         break;;
#     No ) break;;
#   esac
# done
 
# echo ""
# echo "Showing all filename extensions in Finder by default"
# defaults write NSGlobalDomain AppleShowAllExtensions -bool true
 
echo ""
echo "Showing status bar in Finder by default"
defaults write com.apple.finder ShowStatusBar -bool true

echo ""
echo "Showing Path bar in Finder by default"
defaults write com.apple.finder ShowPathbar -bool true


echo ""
echo "Allowing text selection in Quick Look/Preview in Finder by default"
defaults write com.apple.finder QLEnableTextSelection -bool true
 
# echo ""
# echo "Displaying full POSIX path as Finder window title"
# defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
 
 
# echo ""
# echo "Use column view in all Finder windows by default"
# defaults write com.apple.finder FXPreferredViewStyle Clmv
 
echo ""
echo "Avoiding the creation of .DS_Store files on network volumes"
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
 
 
# echo ""
# echo "Enabling snap-to-grid for icons on the desktop and in other icon views"
# /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist
# /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist
# /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist


###############################################################################
# Dock & Mission Control
###############################################################################
 
# Wipe all (default) app icons from the Dock
# This is only really useful when setting up a new Mac, or if you don't use
# the Dock to launch apps.
#defaults write com.apple.dock persistent-apps -array
 
echo ""
echo "Setting the icon size of Dock items to 36 pixels for optimal size/screen-realestate"
defaults write com.apple.dock tilesize -int 40
 
echo ""
echo "Speeding up Mission Control animations and grouping windows by application"
defaults write com.apple.dock expose-animation-duration -float 0.1
defaults write com.apple.dock "expose-group-by-app" -bool true


###############################################################################
# Safari & WebKit
###############################################################################
 
# echo ""
# echo "Hiding Safari's bookmarks bar by default"
# defaults write com.apple.Safari ShowFavoritesBar -bool false
 
# echo ""
# echo "Hiding Safari's sidebar in Top Sites"
# defaults write com.apple.Safari ShowSidebarInTopSites -bool false
 
# echo ""
# echo "Disabling Safari's thumbnail cache for History and Top Sites"
# defaults write com.apple.Safari DebugSnapshotsUpdatePolicy -int 2
 
# echo ""
# echo "Enabling Safari's debug menu"
# defaults write com.apple.Safari IncludeInternalDebugMenu -bool true
 
# echo ""
# echo "Making Safari's search banners default to Contains instead of Starts With"
# defaults write com.apple.Safari FindOnPageMatchesWordStartsOnly -bool false
 
echo ""
echo "Removing useless icons from Safari's bookmarks bar"
defaults write com.apple.Safari ProxiesInBookmarksBar "()"
 
echo ""
echo "Allow hitting the Backspace key to go to the previous page in history"
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2BackspaceKeyNavigationEnabled -bool true
 
echo ""
echo "Enabling the Develop menu and the Web Inspector in Safari"
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" -bool true
 
echo ""
echo "Adding a context menu item for showing the Web Inspector in web views"
defaults write NSGlobalDomain WebKitDeveloperExtras -bool true 


