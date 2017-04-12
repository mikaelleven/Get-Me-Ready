Get Me Ready - Automagical Computer Setup
=========================================

# What is Get Me Ready?

_Get Me Ready (GMR)_ is a script to easily set up your computer with all the basic the tools and typical settings you normally need. A _"computer bootstrapper"_ if you will. The **purpose of the script is to significantly reduce the time needed to install a fresh computer** through automation of all the major common parts of the installation. 

# Real time saver! 
First of all you save time by not having to recall all the applications you typically installs and go finding them on the web. Especially you save time by skipping the tedious task of starting each and every installation, answer some basic questions and wait for the installation to complete before you proceed with the next one. The scripts takes care of all this for you in one continuous installation process. Albeit time consuming, you don't need to be there to watch. Instead you can enjoy your brew of choice while the computer does all the job (almost anyway, you might need to check in a couple of times to supply a password or answering a question).

# Discover new tools
On top of being a great time saver this script is also a nice collection of popular (and in some regards _'best practice'_) tools. This could be a great way of discovering new tools and applications.

# Increased productivity
Another nice feature of GMR is the productivity increasing tools and tweaks that is part of the package. Power users typically depend heavily on keyboard shortcuts and their efficiency on a daily basis is directly correlated to the availability of smart keyboard shortcuts. This is one area where GMR aims to add missing functionality (such as mimicking a great Windows feature on Mac or vice versa) and increasing the number of tasks that can be performed solely using the keyboard. One important tool here is the keyboard controlled _application launcher_ which works like a powerful and optimized variant of the Start Menu on Windows and Spotlight on the Mac. 

Currently **Launchy** (on Windows) and **Alfred** (on Mac) is the application launchers of choice for GMR and they both offers some improvements over the default options found in macOS and Windows.

> _In recent versions of Windows and OS X the default application launchers has been improved and now behaves more like these stand-alone application launchers (altough the stand-alone alternatives still does offer some additional features)._

# Customize to your liking 
Although the script contains a collection of useful and popular tools and applications, your personal preferences may vary. Therefore the script is divided into some major collection/groups of applications such as Productivity Tools, Development Tools and Power Tools. You could easily exclude any of these collections. And even if you want the collection in general you might want to skip a application (or two). This is also easily achieved (more on this later).

# Comes in two flavors - Mac and Windows 
Due to fundamental differences between the Mac and Windows platforms GMR is split into two entirely separated scripts with their unique collections of applications and tweaks (although some of the tools is multi-platform and thereby available in both script).

**Get My PC Ready (GMPR)**
Read more about _"GMR for Windows"_:
> TBD
 
**Get My Mac Ready (GMMR)**
Read more about _"GMR for Mac"_ - __
> http://goo.gl/v8AiaA

# How does it work (a bit technical)
Basically GMR is a script relying on core OS functionality of batch processing (Bash/Batch) and a package manager (https://goo.gl/RZHZlg). On Windows the batch processing is managed by Batch (aka "Command Prompt") and the package manager is Chocolately. On Mac the batch processing is managed by Bash (similar as in Unix/linux) and the package manager is Homebrew.

The GMR script for each platform is actually a collection of multiple scripts following this basic structure:
- _GetMyPCReady / GetMyMacReady:_ The base script responsible for the installation of the package manager and execution of the other scripts
- _Common:_ Basic tools typically relevant for most users (i.e. antivirus, Sublime Text, f.lux, web browsers, Spotify etc)
- _Productivity:_ Useful tools for typical users (i.e Dropbox, LastPass, Evernote, Office etc) users  
- _Powertools:_ More advanced tools for power users (i.e. disk tools, file sync etc)
- _Development:_ Tools specifically aimed at developers (i.e. Git, Visual Studio, NodeJS, Electron) 

## Only interested in parts of GMR?
No problem! You can easily select which package(s) you want to include. And thanks to the nature of scripting it is easy to both exclude specific applications and tweaks as well as it is easy to add your own applications to your script.

You can even totally skip the installation script and simply *use GMR as a guide for recommended applications* for you to install manually, this is totally up to you!

*Customize the installation*
In the base script (_GetMyPCReady.bat_ on Windows and _GetMyMacReady.sh_ on macOS) you will find a section where the other scripts is executed. Review the example below where the first four scripts will be executed and the last two is commented out with the hash symbol ("#") and will not be included.

```bash
### INSTALL PACKAGES ###
source "$DIR/Common.sh" # Install common applications
source "$DIR/Productivity.sh" # Install productivity applications
source "$DIR/Powertools.sh" # Install power tools
source "$DIR/Development.sh" # Install development tools
#source "$DIR/NiceToHave.sh" # Install nice-to-have applications
#source "$DIR/Personal.sh" # Install personal applications
```
 
Similarily you can influence which specific applications that will be installed by commenting out specifc lines in each of these package scripts above. Review this example below where the web browsers Google Chrome and Firefox will be installed while Opera will be excluded. 

```bash
# Web browsers
brew cask install google-chrome # Google Chrome
brew cask install firefox # FireFox
#brew cask install opera-next # Opera
```
