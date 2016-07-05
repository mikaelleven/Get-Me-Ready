===========================================================================
=[ GetMyMacReady - by Mikael Levén ]=======================================
===========================================================================

Open terminal in this folder and run the following command:

chmod +x GetMyMacReady.sh && ./GetMyMacReady.sh


You will be prompted several times for your sudo password as well as other questions.

Please also be patient while the Xcode Command Line Tools are being installed, this might take some time to process. And it is needed for Brew to work.

And overall, it will take some time to download and install all these applications. So please be patient, drink a coffee (or what prefer you) and check the progress now and then to answer any question that might pop up during progress.


=[ Contents ]==============================================================

All applications and utilities listed below will be installed (unless you explicitly exclude any of them).

General tools and system utilities:
Homebrew (w/ Cask)
XtraFinder
iTerm2
Alfred (w/ tweak for Homebrew)
HyperDock
WhiteClock2
f.lux
SmcFanControl
Caffeine
Java
FlashPlayer


General applications:
Google Chrome
FireFox
TeamViewer
VLC Player
Spotify
FileZilla
LastPass


Productivity tools:
Dropbox
Slack
Evernote
Skitch
Google Hangouts
Skype
OmniGraffle
Google Drive


Developer tools:
Sublime Text 3
Atom
GitHub
SourceTree
Mono SDK
Xamarin Studio
Vagrant
VirtualBox


Hacks:
And finally we have a special hack fixing the upper left corner of your screen as a shortcut to lock your screen. Really handy time saver. Although you have the “lock” command in Alfred that is pretty convenient as well.


=[ Customization ]===========================================================

In the GetMyMacReady.sh it is easy to exclude any of the three main packages:
Core
Productivity
Developer

Just add # (“hash”) before any of these lines, for example (to exclude Developer):

#source "$DIR/Development.sh"

It is also possible to exclude the “Hot corner” hack:
#source "$DIR/HotCorners.sh"

