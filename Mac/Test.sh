#!/bin/bash

# if [ -e /Applications/Alfred\ 2.app ]
if [ -e /Applications/Alfred\ 2.app ]
then
	open /Applications/Alfred\ 2.app
else
	if [ -e /Applications/Alfred.app ]
	then
		open /Applications/Alfred.app
	else
		curl -s http://getmacapps.com/raw/1k4fnc6pt | sh # Alfred
	fi	
fi

