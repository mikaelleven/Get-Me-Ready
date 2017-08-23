#!/bin/bash

echo "Tweaking your terminal (bash)"
echo 

# Script & aliases
#echo "alias flushdns=''" >> ~/.bashrc

### Set ls options and enable colors ###
export LS_OPTIONS='--color=auto -h'
echo "alias ls='ls $LS_OPTIONS -CF'" >> ~/.bashrc
echo "alias ll='ls $LS_OPTIONS -alF'" >> ~/.bashrc
echo "alias la='ls $LS_OPTIONS -lA'" >> ~/.bashrc
echo "alias l='ls'" >> ~/.bashrc

### Mimic Windows behavior ###
echo "alias cd..='cd ..'" >> ~/.bashrc
echo "alias dir='ls'" >> ~/.bashrc

#echo "export LSCOLORS='ExFxcxdxCxegedabagacad' # Set actual ls colors" >> ~/.bashrc

#export PS1='\h[\[\033[01;33m\]\u\[\e[00m\]]\[\e[01;8;31m\]\[\033[00m\]:\[\033[00;36m\]\w\[\033[00m\]\$ ' >> ~/.bashrc





