#!/bin/bash

echo "Tweaking your terminal (bash)"
echo 

# Script & aliases
echo "alias flushdns='dscacheutil -flushcache && sudo killall -HUP mDNSResponder'" >> ~/.bash_profile

echo "alias brew-update='brew update && brew upgrade && brew cu && brew cleanup'" >> ~/.bash_profile

echo "export LS_OPTIONS='--color=auto'" >> ~/.bash_profile
echo "eval "`dircolors`"" >> ~/.bash_profile
echo "alias ls='ls $LS_OPTIONS'" >> ~/.bash_profile
echo "alias ll='ls $LS_OPTIONS -l'" >> ~/.bash_profile
echo "alias l='ls $LS_OPTIONS -lA'" >> ~/.bash_profile

echo "alias cd..='cd ..'" >> ~/.bash_profile



