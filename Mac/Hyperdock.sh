#!/bin/bash

mkdir ~/getmacapps_temp
cd ~/getmacapps_temp

curl -L -o HyperDock.dmg "http://hyperdock.bahoom.com/HyperDock.dmg"
hdiutil mount HyperDock.dmg
cp -R "/Volumes/HyperDock/HyperDock.prefpane" ~/Library/PreferencePanes
hdiutil unmount "/Volumes/HyperDock"
rm HyperDock.dmg
