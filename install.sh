#!/usr/bin/env bash

# Displays a confirm prompt for the given input.
function confirm() {
    echo -n "You entered $@ - is this correct? (Y/n)"
    read -e answer
    for response in n N no No NO; do
        if [ "_$answer" == "_$response" ]; then
            echo "Cancelling..."
            exit 1
        fi
    done
    
    return 1
}

# Checks if the given command is installed.
function is_installed() {
    if [ $(which $@ | wc -l) -gt 0 ]; then
        return 1
    fi
    return 0
}

#--------------------------------------------------------------------
#
# R E A D   I N   I N I T I A L   U S E R   D A T A
#
#--------------------------------------------------------------------

# Read in the user name.
while [ "$user" == "" ]; do
    echo -n "What username would you like to use? "
    read user
done 
confirm $user

# Read in the domain name.
while [ "$domain" == "" ]; do
    echo -n "What domain would you like to access your server with? "
    read domain
done 
confirm $domain
