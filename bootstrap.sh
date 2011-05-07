#!/usr/bin/env sh

echo "Installing git..."
sudo apt-get install git-core

echo "Cloning fresh-ubuntu..."
git clone --recursive git://github.com/recurser/fresh-ubuntu.git
cd fresh-ubuntu

echo "Installing..."
./install.sh
