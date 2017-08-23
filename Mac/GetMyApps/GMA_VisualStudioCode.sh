#!/bin/bash

# # Create and open a temporary folder
# mkdir -p ~/.gmmr/temp
# cd ~/.gmmr/temp

# # Download Visual Studio for Mac preview from Microsoft
# curl -L -o ~/.gmmr/temp/VisualStudioCode.zip "https://go.microsoft.com/fwlink/?LinkID=620882"

# # Uncompress the downloaded archive
# unzip ~/.gmmr/temp/VisualStudioCode.zip

# # Move the unzipped application to the applications folder
# mv "Visual Studio Code.app" /Applications

# # Remove the temporary zip archive
# rm ~/.gmmr/temp/VisualStudioCode.zip

brew cask install visual-studio-code

# Fix symbolic link for "code" command (manual install: https://code.visualstudio.com/docs/setup/mac)
# Note: this is required for automatic installation of extensions
ln -s "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" /usr/local/bin/code

### Install extensions >>>

# C#
code --install-extension ms-vscode.csharp

# Python (linter)
code --install-extension donjayamanne.python

# VSCode icons
code --install-extension robertohuertasm.vscode-icons

# Debugger for Chrome
code --install-extension msjsdiag.debugger-for-chrome

# Beatify (JSON, HTML, etc)
code --install-extension HookyQR.beautify

# HTML Snippets
code --install-extension abusaidm.html-snippets

# TypeScript linter
code --install-extension eg2.tslint

# PowerShell support
code --install-extension ms-vscode.PowerShell

# Git history
code --install-extension donjayamanne.githistory

# Angular 2 Snippets
code --install-extension johnpapa.Angular2

# VSCode settings sync (Gist)
code --install-extension Shan.code-settings-sync

# Bootstrap 3 snippets
code --install-extension wcwhitehead.bootstrap-3-snippets

# Python sytax highlighter
code --install-extension magicstack.MagicPython

# React Native tools
code --install-extension vsmobile.vscode-react-native

# PHP Code format
code --install-extension Kasik96.format-indent

# Spell and grammar checker
code --install-extension seanmcbreen.Spell

# Code runner for various languages (C#, JS, Python, LUA etc)
code --install-extension formulahendry.code-runner

# Style linter (SASS, LESS, CSS)
code --install-extension shinnn.stylelint

# REST client
code --install-extension humao.rest-client

# Python syntax highlightning, snippets & linting
code --install-extension tht13.python

# NPM support/tools
code --install-extension eg2.vscode-npm-script

# Docker support
code --install-extension PeterJausovec.vscode-docker

# React snippets
code --install-extension xabikos.ReactSnippets

# Color picker
code --install-extension anseki.vscode-color

# jQuery snippets
code --install-extension donjayamanne.jquerysnippets

# PRettify JSON
code --install-extension mohsen1.prettify-json

# HTML CSS SUport
code --install-extension ecmel.vscode-html-css

# Atom Dark Theme
code --install-extension akamud.vscode-theme-onedark

# Document This for JS
code --install-extension joelday.docthis

# PAth intellisense (autocomplete filenames)
code --install-extension christian-kohler.path-intellisense

# MAterial Theme kit
code --install-extension ms-vscode.Theme-MaterialKit

# Material Icon theme
code --install-extension PKief.material-icon-theme

# SASS syntax highlightning
code --install-extension robinbentley.sass-indented

# Angular 2 TS + HTML snippets
code --install-extension UVBrain.Angular2

# Yeoman project scaffolding
code --install-extension samverschueren.yo

# NPM intellisense
code --install-extension christian-kohler.npm-intellisense

# Auto close tag
code --install-extension formulahendry.auto-close-tag

# Guide lines
code --install-extension spywhere.guides

# TODO:s
code --install-extension MattiasPernhult.vscode-todo

# Nativrscript support
code --install-extension Telerik.nativescript

# Angualar 2 syntax highlightning
code --install-extension nwallace.language-vscode-javascript-angular2

# Flatland Monokai theme
code --install-extension gerane.Theme-FlatlandMonokai

# One Dark Monokai theme
code --install-extension azemoh.one-monokai

# Visual Studio Team Services support
code --install-extension ms-vsts.team

# Change Case
code --install-extension wmaurer.change-case

# HTNL 5 boilerplate generator
code --install-extension sidthesloth.html5-boilerplate

# Minifyer (CSS / JS / HTML)
code --install-extension HookyQR.minify

# 1337 Theme
code --install-extension ms-vscode.Theme-1337

# Lua support
code --install-extension keyring.Lua

# Sublime Text Keymap
code --install-extension ms-vscode.sublime-keybindings

# MS SQL 
code --install-extension ms-mssql.mssql

# Waka Time support
code --install-extension WakaTime.vscode-wakatime

# Hex Dump
code --install-extension slevesque.vscode-hexdump

# Auto complete filename
code --install-extension JerryHong.autofilename

# Officla VS2015 Icons
code --install-extension jtlowe.vscode-icon-theme

# Envode / Decode text (base64 etc)
code --install-extension mitchdenny.ecdc

# Material Neutral Theme
code --install-extension bernardodsanderson.theme-material-neutral

# Rainbow Brackets
code --install-extension 2gua.rainbow-brackets

# RegEx previewer
code --install-extension chrmarti.regex

# Nginx syntax highlighter
code --install-extension shanoor.vscode-nginx

# Ruby support
code --install-extension rebornix.Ruby

# Vagrant support
code --install-extension marcostazi.VS-code-vagrantfile

# Gitflow support
code --install-extension vector-of-bool.gitflow
