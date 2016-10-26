#!/bin/bash

echo "Installing NodeJS, please wait..."
echo.

# Install Node Version Manager (NodeJS)
touch ~/.profile # Prepare NVM
touch ~/.bash_profile # Prepare NVM
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.31.3/install.sh | bash # Node Version Manager (NVM)

# Init NVM (paths)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm

# Get lastest or specific version (NOT NEEDED) 
#nodelts="$(nvm ls-remote --lts | tail -n1 | grep -o 'v\d\(.\d\)*')"
#nvm install $nodelts

# Install latest LTS version of NodeJS
nvm install --lts

echo.
echo "NodeJS installed!"

