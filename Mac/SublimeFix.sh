#!/bin/bash

echo "==============================================="
echo "SublimeFix (Mac) v1.0 - Created by Mikael Levén"
echo "==============================================="
echo 

echo "Please make sure you have updated with your own settings (if needed):"
echo "- Your license file"
echo "- Path to your Package Sync folder"
echo "- Your up-to-date Package Control settings file"
echo ""
echo "Note: Check out the Readme.md for further details."
echo ""

# no solution to automate AppStore installs
echo
read -p "Make sure Sublime Text isn't running and then press any key to begin configuration of Sublime Text... " -n1 -s
echo  ""



DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


function setupSublimeText() { 
	createTempFolder
	createGMMRFolder

	createSublimeFolders

	installThemes

	installPackageControl

	copySettings

	cleanGMMRFolder
}



function createTempFolder ()
{ 	# Make sure temp folder exists
	if [ ! -e ~/Temp ] 
	then
		mkdir ~/Temp
	fi
}


function createGMMRFolder ()
{ 	# Make sure _GMMR folder exists
	if [ ! -e ~/Temp/_GMMR ]
	then
		mkdir ~/Temp/_GMMR
	fi
}



function createSublimeFolders ()
{ 	
	if [ ! -e ~/Library/Application\ Support/Sublime\ Text\ 3/ ]
	then
		mkdir ~/Library/Application\ Support/Sublime\ Text\ 3/
	fi

	if [ ! -e ~/Library/Application\ Support/Sublime\ Text\ 3/Installed\ Packages ]
	then
		mkdir ~/Library/Application\ Support/Sublime\ Text\ 3/Installed\ Packages
	fi

	if [ ! -e ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/ ]
	then
		mkdir ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/
	fi


	if [ ! -e ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/ ]
	then
		mkdir ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/
	fi

}


function cleanGMMRFolder ()
{ 	
	if [ -e ~/Temp/_GMMR ]
	then
		rm -rf ~/Temp/_GMMR
	fi
}

function installThemes ()
{	# 
	cd ~/Temp/_GMMR

	installSodaTheme
	installBrogrammerTheme
	installAtomDark
}





function installPackageControl ()
{	# Installing Package Control
	if [ -e "$sublimeInstalledPackagesDir/Package Control.sublime-package" ] 
	then
		echo "Package Control already installed"
		return
	fi

	curl -L -o Package\ Control.sublime-package "https://sublime.wbond.net/Package%20Control.sublime-package"
	mv -f Package\ Control.sublime-package "$sublimeInstalledPackagesDir"
}




function copySettings ()
{	
	# Copy license
	if [ -e "$DIR/../Shared/License.sublime_license" ] 
	then
		if [ ! -e "$sublimeDir/Local/License.sublime_license" ] 
		then		
			cp -R "$DIR/../Shared/License.sublime_license" "$sublimeDir/Local"
			echo "Sublime Text license found"
		else
			echo "License found but was already installed"
		fi
	fi

	# Copy Sync settings
	if [ -e "$DIR/../Shared/Package Syncing.sublime-settings" ] 
	then
		if [ ! -e "$sublimePackagesDir/User/Package Syncing.sublime-settings" ] 
		then		
			echo "Sublime Text Package Sync settings found"
			cp -R "$DIR/../Shared/Package Syncing.sublime-settings" "$sublimePackagesDir/User"
		else
			echo "Package Sync Settings found but was already installed"
		fi
	fi

	# Copy Package Control settings
	if [ -e "$DIR/../Shared/Package Control.sublime-settings" ] 
	then
		if [ ! -e "$sublimePackagesDir/User/Package Control.sublime-settings" ] 
		then		
			echo "Sublime Text Package Control settings found"
			cp -R "$DIR/../Shared/Package Control.sublime-settings" "$sublimePackagesDir/User"
		else
			echo "Package Control settings found but was already installed"
		fi
	fi

	# Copy Preferences
	if [ -e "$DIR/../Shared/Preferences.sublime-settings" ] 
	then
		if [ ! -e "$sublimePackagesDir/User/Preferences.sublime-settings" ] 
		then		
			echo "Sublime Text Preferences found"
			cp -R "$DIR/../Shared/Preferences.sublime-settings" "$sublimePackagesDir/User"
		else
			echo "Preferences found but was already installed"
		fi
	fi
}



function installSodaTheme ()
{	# Installing Soda Theme
	if [ ! -e "$sublimePackagesDir/Theme - Soda" ] 
	then
		curl -L -o SodaTheme.zip "https://github.com/buymeasoda/soda-theme/archive/master.zip"
		unzip -o SodaTheme.zip
		mv soda-theme-master "./Theme - Soda"
		mv -f "Theme - Soda" "$sublimePackagesDir"
		# mv SodaTheme.app /XXXX
		rm SodaTheme.zip

	else
		echo "Theme Soda already installed"
	fi

	if [ ! -e "$sublimePackagesDir/User/Espresso Soda.tmTheme" ] && [ ! -e "$sublimePackagesDir/User/Espresso Soda.tmTheme" ]
	then
		curl -L -o colour-schemes.zip "http://buymeasoda.github.com/soda-theme/extras/colour-schemes.zip"
		unzip -o colour-schemes.zip -d "$sublimePackagesDir/User"
		rm colour-schemes.zip
	else
		echo "Theme Soda additional colour schemes already installed"
	fi
	
}




function installAtomDark ()
{	# Installing Soda Theme
	if [ ! -e "$sublimePackagesDir/User/Atom Dark.tmTheme" ] 
	then
		curl -L -o AtomDark.zip "https://github.com/jasontruluck/Atom-Dark.tmTheme/archive/master.zip"
		unzip -o AtomDark.zip
		mv -f "Atom-Dark.tmTheme-master/Atom Dark.tmTheme" "$sublimePackagesDir/User"
		rm AtomDark.zip
		rm -rf Atom-Dark.tmTheme-master
	else
		echo "AtomDark colour scheme already installed"
	fi

	# Install custom version of Atom Dark
	if [ -e "$DIR/../Shared/Sublime Atom Dark ML.tmTheme" ] 
	then
		if [ ! -e "$sublimePackagesDir/User/Sublime Atom Dark ML.tmTheme" ]
		then		
			echo "Custom Atom Dark colour scheme found"
			cp -R "$DIR/../Shared/Sublime Atom Dark ML.tmTheme" "$sublimePackagesDir/User"
		else
			echo "Custom Atom Dark colour scheme found but was already installed"
		fi
	fi	
}

function installBrogrammerTheme ()
{	# Installing Soda Theme
	if [ -e "$sublimePackagesDir/Theme - Brogrammer" ] 
	then
		echo "Theme Brogramme already installed"
		return
	fi

	curl -L -o brogrammer-theme-master.zip "https://github.com/kenwheeler/brogrammer-theme/archive/master.zip"
	unzip -o brogrammer-theme-master.zip
	mv brogrammer-theme-master "./Theme - Brogrammer"
	mv -f "Theme - Brogrammer" "$sublimePackagesDir"
	# mv SodaTheme.app /XXXX
	rm brogrammer-theme-master.zip
}




# sublimeDir="~/Library/Application\ Support/Sublime\ Text\ 3"
sublimeDir=$(echo ~/Library/Application Support/Sublime Text 3)
sublimePackagesDir="$sublimeDir/Packages"
sublimeInstalledPackagesDir="$sublimeDir/Installed Packages"


# if [ -e /Applications/Alfred\ 2.app ]
# sd=$(echo ~/Library/Application\ Support)
# echo $sd  

if [ -e /Applications/Sublime\ Text.app ]
then
	echo "Preparing Sublime Text"
	setupSublimeText

	# no solution to automate AppStore installs
	echo
	read -p "Sublime Text is ready and will be started automatically. Sublime Text will need some time to dowload all packages, so please be patient. Press any key to continue..." -n1 -s
	echo  ""

	open /Applications/Sublime\ Text.app
else
	echo "Please make sure Sublime Text 3 is installed"
fi


# ###############################################################################
# # Sublime Text
# ###############################################################################
# echo ""
# echo "Do you use Sublime Text 3 as your editor of choice and is it installed?"
# select yn in "Yes" "No"; do
#   case $yn in
#     Yes ) echo ""
        echo "Linking Sublime Text command line"
        ln -s "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl" /usr/local/bin/subl
        echo ""
        echo "Setting Git to use Sublime Text as default editor"
        git config --global core.editor "subl -n -w"
        echo ""
        # echo "Removing Mission Control as it interferes with Sublime Text keyboard shortcut for selecting multiple lines"
        # defaults write com.apple.dock mcx-expose-disabled -bool TRUE
#         break;;
#     No ) break;;
#   esac
# done



# # Move sublime settings

# # install package control
# echo "Installing package control and syncing settings"
# mkdir ~/Library/Application\ Support/Sublime\ Text\ 3/
# mkdir ~/Library/Application\ Support/Sublime\ Text\ 3/Installed\ Packages
# mkdir ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/
# mkdir ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/

# wget -O ~/Library/Application\ Support/Sublime\ Text\ 3/Installed\ Packages/Package\ Control.sublime-package "https://sublime.wbond.net/Package%20Control.sublime-package" 
# # move sublime settings
# cp -R ../assets/sublime/ ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/
# # move sublime package control settings

