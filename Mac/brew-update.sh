#!/bin/bash

brew=/usr/local/bin/brew
logger=/usr/bin/logger

echo -ne Updating Homebrew... 
$brew update 2>&1  | $logger -t brewup.update
$brew cu 2>&1  | $logger -t brewup.update
$brew upgrade 2>&1 | $logger -t brewup.upgrade
$brew cleanup 2>&1 | $logger -t brewup.cleanup
echo "Done! Run '$ cat /var/log/system.log | grep brewup' to view log entries"
