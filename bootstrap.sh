#!/usr/bin/env sh

if [ $(which git | wc -l) -eq 0 ]; then
    echo "Installing git..."
    sudo apt-get install git-core
fi

echo "Cloning fresh-ubuntu..."
git clone --recursive git://github.com/recurser/fresh-ubuntu.git
cd fresh-ubuntu

echo "Installing..."
./install.sh
