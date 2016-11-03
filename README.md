Get Me Ready - Automagical Computer Setup
=========================================

# What is Get Me Ready?

_Get Me Ready (GMR)_ is a script to easily set up your computer with all the basic the tools and typical settings you normally need. A _"computer bootstrapper"_ if you will. The **purpose of the script is significantly reduce the time needed to install a fresh computer** through automation of all the major common parts of the installation. 

# Real time saver! 
First of all you save time by not having to recall all the applications you typically installs and go finding them on the web. Especially you save time by skipping the tedious task of starting each and every installation, answer some basic questions and wait for the installation to complete before you proceed with the next one. The scripts takes care of all this for you in one continuous installation process. Albeit time consuming, you don't need to be there to watch. Instead you can enjoy your brew of choice while the computer does all the job (almost anyway, you might need to check in a couple of times to supply a password or answering a question).

# Discover new tools
On top of being a great time saver this script is also a nice collection of popular (and in some regards _'best practice'_) tools. This could be a great way of discovering new tools and applications.

# Increased productivity
Another nice feature of GMR is the productivity increasing tools and tweaks that is part of the package. Power users typically depend heavily on keyboard shortcuts and their efficiency on a daily basis is directly correlated to the availability of smart keyboard shortcuts. This is one area where GMR aims to add missing functionality (such as mimicking a great Windows feature on Mac or vice versa) and increasing the number of tasks that can be performed solely using the keyboard. One important tool here is the keyboard controlled _application launcher_ which works like a powerful and optimized variant of the Start Menu on Windows and Spotlight on the Mac. 

Currently **Launchy** (Windows) and **Alfred** (Mac) is the application launchers of choice for GMR and they both offers some improvements to the default solutions found in OS X and Windows

> _In recent versions of Windows and OS X the default application launchers has been improved and now behaves more like these stand-alone application launchers (altough the stand-alone alternatives still does offer some additional features)._

# Customize to your liking 
Although the script contains a collection of useful and popular tools and applications, your personal preferences may vary. Therefore the script is divided into some major collection/groups of applications such as Productivity Tools, Development Tools and Power Tools. You could easily exclude any of these collections. And even if you want the collection in general you might want to skip a application (or two). This is also easily achieved (more on this later).

# Comes in two flavors - Mac and Windows 
Due to fundamental differences between the Mac and Windows platforms GMR is split into two entirely separated scripts with their unique collections of applications and tweaks (although some of the tools is multi-platform and thereby available in both script).

**Get My PC Ready**
Read more about _"GMR for Windows"_:
> XXXX
 
**Get My Mac Ready**
Read more about _"GMR for Mac"_ - __
> http://goo.gl/v8AiaA

# How does it work (a bit technical)
Basically GMR is a script relying on core OS functionality of batch processing (Bash/Batch) and a package manager (https://goo.gl/RZHZlg). On Windows the batch processing is managed by Batch (aka "Command Prompt") and the package manager is Chocolately. On Mac the batch processing is enabled by Bash (similar as in Unix/linux) and the package manager is Homebrew.

The GMR script for each platform is actually a collection of multiple scripts following this basic structure:
- GetMyPCReady / GetMyMacReady: The base script responsible for the installation of the package manager and execution of the other scripts
- Core: Installs all basic tools typically relevant for types of users
- Productivity Tools
- Power Tools: 
- Development Tools: 


Regardless if you are interested in the GMMR script or not, the combination of the Ctrl+Tab window switch-fix, Alfred, XtraFinder and HyperDock is a real time saver for me. It really enhances my productivity and effectiveness on a daily basis. And combined with some real great tools this really makes my days a lot easier - especially Sublime Text, Dropbox and LastPass.
So even if you are not interested in the GMMR script itself, maybe you could find some real gems here that enhances your productivity. If so, skip down to the Manual/other Tweaks-section or browse through the What’s included in GMMR-section.
How does the script work (read this before you use GMMR)

GMMR is a simple Bash script that will install most of the applications you typically need. A computer bootstrapper if you will. The script will also do some basic tweaking of the OS. The applications are grouped into three main categories: Core, Productivity and Developer.
There is some applications that is not possible to script that must be manually installed. And we also need to semi-manually install all applications from App Store. It is also advised to exclude all applications from GMMR that is already installed via App Store.
And the rest of the Mac OS X tweaks that isn’t included in the script will you find I you scroll down this document.
What if I’m not interested in one of the applications or a whole package?

Should you lack interest of a whole package it’s easy to exclude (comment out) the whole group. The same goes for single applications. Just use the hash (#) comment on each line you want to exclude.
For example should you want to exclude the whole Development package, simply comment out that row in GetMyMacReady.sh like this:
#source "$DIR/Development.sh"
Or if you want to exclude only Atom application from the Development package:
#brew cask install --appdir="/Applications" atom




⌘⌘
⇧⇧⟵⇥↵




