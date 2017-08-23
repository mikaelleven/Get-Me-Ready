#!/bin/bash

echo "Tweaking your terminal (bash)"
echo 

# Script & aliases
echo "alias flushdns='dscacheutil -flushcache && sudo killall -HUP mDNSResponder'" >> ~/.bash_profile
echo "alias brew-update='brew update && brew upgrade && brew cu && brew cleanup'" >> ~/.bash_profile

### Set ls options and enable colors
export LS_OPTIONS='-G -h'
echo "alias ls='ls $LS_OPTIONS'" >> ~/.bash_profile
echo "alias ll='ls $LS_OPTIONS -l'" >> ~/.bash_profile
echo "alias l='ls $LS_OPTIONS -lA'" >> ~/.bash_profile
echo "alias cd..='cd ..'" >> ~/.bash_profile
echo "alias dir='ls'" >> ~/.bash_profile

echo "export CLICOLOR=1 # Globally enables colors in ls" >> ~/.bash_profile # Equivivalent to -G option in ls

#echo "export LSCOLORS=GxFxCxDxBxegedabagaced" >> ~/.bash_profile
echo "export LSCOLORS='ExFxcxdxCxegedabagacad' # Set actual ls colors" >> ~/.bash_profile


### Enable Bash format & colors (username etc) ###

#export PS1='\[\033[01;8;33m\]\u\[\e[00m\]\[\e[01;8;31m\]@\h\[\033[00m\]:\[\033[00;01;8;36m\]\w\[\033[00m\]\$ '
export PS1='\h[\[\033[01;33m\]\u\[\e[00m\]]\[\e[01;8;31m\]\[\033[00m\]:\[\033[00;36m\]\w\[\033[00m\]\$ ' >> ~/.bash_profile

#export PS1='\[\e  [01;8;33m\]\u\[\e[0m\]@\[\e[0;32m\]\h\[\e[0m\]:\[\e[0;34m\]\w\[\e[0m\]\$ '




