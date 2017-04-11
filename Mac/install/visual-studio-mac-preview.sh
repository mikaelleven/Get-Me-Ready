#!/bin/bash

# Create and open a temporary folder
mkdir -p ~/.gmmr/temp
cd ~/.gmmr/temp

# Download Visual Studio for Mac preview from Microsoft
curl -L -o ~/.gmmr/temp/VisualStudioforMacPreviewInstaller.dmg "https://aka.ms/vs/mac/preview1/y2odn5"

# Mount the downloaded disk image
hdiutil mount -nobrowse ~/.gmmr/temp/VisualStudioforMacPreviewInstaller.dmg

# Execute the VS for Mac installer (and wait for it to finish)
open --wait-apps "/Volumes/Visual Studio for Mac Preview Installer/Install Visual Studio for Mac Preview.app"

# Unmount the VS for Mac disk image
hdiutil unmount "/Volumes/Visual Studio for Mac Preview Installer"

# Remove the temporary disk image
rm ~/.gmmr/temp/VisualStudioforMacPreviewInstaller.dmg
