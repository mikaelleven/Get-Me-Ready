#!/bin/bash

# Get the user currently logged into the console and store in the variable "user"
user=`ls -l /dev/console | cut -d " " -f 4`

# Set line separator to be used in for/while loops
IFS=$'\n'

###
# Set hotcorner actions. Disable "Disable Screen Saver" when found.
###
## The following are the values of each option in the GUI
# Start Screen Saver = 5
# Modifier = 0
# Disable Screen Saver = 6
# Modifier = 0
# Mission Control = 2
# Modifier = 0
# Application Windows = 3
# Modifier = 0
# Desktop = 4
# Modifier = 0
# Dashboard = 7
# Modifier = 0
# Notification Center = 12
# Modifier = 0
# Launchpad = 11 
# Modifier = 0
# Put Display to Sleep = 10
# Modifier = 0
# None = 1
# Modifier = 1048576
##
a=`defaults read /Users/$user/Library/Preferences/com.apple.dock.plist | grep "\-corner\""`
c = ``
for corner in $a
	do
	# echo $corner
	cornerval=`echo $corner | cut -d "=" -f2 | cut -d ";" -f1 | sed 's/ //g'`
	corner=`echo $corner | cut -d "\"" -f 2 | cut -d "-" -f 1,2`
	echo $corner
	echo $cornerval

	if [ "$cornerval" = "6" ];
		then
		echo Hotcorner - Disable screensaver found on $corner!!!
		echo We gon\' fix that! # Setting the corner action to 1(None)
		sudo -u $user defaults write /Users/$user/Library/Preferences/com.apple.dock.plist $corner-corner -int 1
		sudo -u $user defaults write /Users/$user/Library/Preferences/com.apple.dock.plist $corner-modifier -int 1048576
		changesmade="yes"
	fi
	
	if [ "$corner" = "wvous-tl" ];
		then

		echo "Add 'Put display to sleep' as top-left hot corner"
		sudo -u $user defaults write /Users/$user/Library/Preferences/com.apple.dock.plist $corner-corner -int 10
		sudo -u $user defaults write /Users/$user/Library/Preferences/com.apple.dock.plist $corner-modifier -int 0
		changesmade="yes"
		c = "ok"
	fi	
done

if [ "$c" = "" ];
	then
	echo "Add 'Put display to sleep' as top-left hot corner"
	sudo -u $user defaults write /Users/$user/Library/Preferences/com.apple.dock.plist wvous-tl-corner -int 10
	sudo -u $user defaults write /Users/$user/Library/Preferences/com.apple.dock.plist wvous-tl-modifier -int 0

	changesmade="yes"
fi


# If changes were made then the dock needs to be restarted for them to take affect
if [ "$changesmade" = "yes" ]; then killall -HUP Dock; fi