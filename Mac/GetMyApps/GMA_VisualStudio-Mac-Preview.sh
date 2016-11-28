#!/bin/bash

mkdir -p ~/.gmmr/temp
cd ~/.gmmr/temp

# Installing GitHub
curl -L -o ~/.gmmr/temp/VisualStudioforMacPreviewInstaller.dmg "https://aka.ms/vs/mac/preview1/y2odn5"

hdiutil mount -nobrowse ~/.gmmr/temp/VisualStudioforMacPreviewInstaller.dmg
#cp -R "/Volumes/Visual Studio for Mac Preview Installer/" /Applications

open --wait-apps "/Volumes/Visual Studio for Mac Preview Installer/Install Visual Studio for Mac Preview.app"
hdiutil unmount "/Volumes/Visual Studio for Mac Preview Installer"
rm ~/.gmmr/temp/VisualStudioforMacPreviewInstaller.dmg

