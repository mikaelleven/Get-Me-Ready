#!/bin/bash

# Create and open a temporary folder
mkdir -p ~/.gmmr/temp
cd ~/.gmmr/temp


### OLD!!! ###

# # Download Visual Studio for Mac preview from Microsoft
# curl -L -o ~/.gmmr/temp/VisualStudioforMacPreviewInstaller.dmg "https://aka.ms/vs/mac/preview1/y2odn5"

# # Mount the downloaded disk image
# hdiutil mount -nobrowse ~/.gmmr/temp/VisualStudioforMacPreviewInstaller.dmg

# # Execute the VS for Mac installer (and wait for it to finish)
# open --wait-apps "/Volumes/Visual Studio for Mac Preview Installer/Install Visual Studio for Mac Preview.app"

# # Unmount the VS for Mac disk image
# hdiutil unmount "/Volumes/Visual Studio for Mac Preview Installer"

# # Remove the temporary disk image
# rm ~/.gmmr/temp/VisualStudioforMacPreviewInstaller.dmg

### OLD!!! ###



### Install Visual Studio ###
brew cask install visual-studio


### Install .NET Core ###

# Download .NET Core from Microsoft
curl -L -o ~/.gmmr/temp/dotnet-dev-osx-x64preview.pkg "https://go.microsoft.com/fwlink/?LinkID=835011"

# Install .NET Core package
#open --wait-apps ~/.gmmr/temp/dotnet-dev-osx-x64preview.pkg
installer -pkg ~/.gmmr/temp/dotnet-dev-osx-x64preview.pkg -target /

# Remove the temporary install package
rm ~/.gmmr/temp/dotnet-dev-osx-x64preview.pkg


### Fix dependencies ###
brew install openssl
# mkdir -p /usr/local/lib
# ln -s /usr/local/opt/openssl/lib/libcrypto.1.0.0.dylib /usr/local/lib/
# ln -s /usr/local/opt/openssl/lib/libssl.1.0.0.dylib /usr/local/lib/
