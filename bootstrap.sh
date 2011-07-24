#!/usr/bin/env sh

if [ $(which git | wc -l) -eq 0 ]; then
    echo "Installing git..."
    sudo aptitude -y install git-core
fi

echo "Cloning ubuntu-fresh..."
cd /tmp
rm -Rf ubuntu-fresh
git clone --recursive git://github.com/recurser/ubuntu-fresh.git
cd fresh-ubuntu

echo "Installing..."
./install.sh
