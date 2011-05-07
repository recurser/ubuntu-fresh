#!/usr/bin/env sh

if [ $(which git | wc -l) -eq 0 ]; then
    echo "Installing git..."
    sudo aptitude -y install git-core
fi

if [ -d fresh-ubuntu]; then
    echo "Removing old fresh-ubuntu folder..."
    rm -Rf fresh-ubuntu
fi

echo "Cloning fresh-ubuntu..."
git clone --recursive git://github.com/recurser/fresh-ubuntu.git
cd fresh-ubuntu

echo "Installing..."
./install.sh
