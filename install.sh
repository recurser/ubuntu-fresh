#!/usr/bin/env sh

# Displays a confirm prompt for the given input.
confirm() {
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
is_installed() {
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
while [ "_$user" == "_" ]; do
    echo -n "What username would you like to use? "
    read user
done 
confirm $user

# Read in the domain name.
while [ "_$domain" == "_" ]; do
    echo -n "What domain would you like to access your server with? "
    read domain
done 
confirm $domain
# Read in the full name.
while [ "$full_name" == "" ]; do
    echo -n "What is your full name? "
    read full_name
done 
confirm $full_name

# Read in the full email address.
while [ "$email" == "" ]; do
    echo -n "What is your email address? "
    read email
done 
confirm $email


#--------------------------------------------------------------------
#
# S E T   U P   G I T   N A M E   A N D   E M A I L
#
#--------------------------------------------------------------------
if [ $(git config --global --get user.name | wc -l) -eq 0 ]; then
     git config --global user.name $full_name
fi

if [ $(git config --global --get user.email | wc -l) -eq 0 ]; then
     git config --global user.name $email
fi


#--------------------------------------------------------------------
#
# S E T   U P   U S E R   A C C O U N T
#
#--------------------------------------------------------------------
if [ $(grep $user /etc/passwd | wc -l) -eq 0 ]; then
    echo "Adding user '$user'"
    adduser $user
fi;



