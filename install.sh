#!/usr/bin/env sh

# Displays a confirm prompt for the given input.
confirm() {
    read -p "You entered $@ - is this correct? (y/N) " answer
        if [ "$answer" == "y" ]; then
            return 1
        fi
    
    echo "Cancelling..."
    exit 1
}

# Checks if the given command is installed.
is_installed() {
    if [ `which $@ | wc -l` -gt 0 ]; then
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
while [ -z "$user" ]; do
    echo "Getting user..."
    read -p "What username would you like to use? " user
done

# Read in the domain name.
while [ -z "$domain" ]; do
    read -p "What domain would you like to access your server with? " domain
done

# Read in the full name.
while [ -z "$full_name" ]; do
    read -p "What is your full name? " full_name
done

# Read in the full email address.
while [ -z "$email" ]; do
    read -p "What is your email address? " email
done


#--------------------------------------------------------------------
#
# S E T   U P   G I T   N A M E   A N D   E M A I L
#
#--------------------------------------------------------------------
if [ `git config --global --get user.name | wc -l` -eq 0 ]; then
    git config --global user.name $full_name
fi

if [ `git config --global --get user.email | wc -l` -eq 0 ]; then
    git config --global user.email $email
fi


#--------------------------------------------------------------------
#
# S E T   U P   U S E R   A C C O U N T
#
#--------------------------------------------------------------------
if [ `grep $user /etc/passwd | wc -l` -eq 0 ]; then
    echo "Adding user '$user'"
    sudo adduser $user
fi;


#--------------------------------------------------------------------
#
# I N S T A L L   B A S E   P A C K A G E S
#
#--------------------------------------------------------------------
sudo apt-get update
sudo apt-get upgrade

sudo aptitude install \
    ant \
    apache2 \
    autoconf \
    build-essential \
    fail2ban \
    fakeroot \
    gcc \
    locales \
    language-pack-en \
    language-pack-ja \
    libapache2-mod-php5 \
    libapache2-mod-suphp \
    locate \
    memcached \
    mercurial \
    mysql-client\
    mysql-common \
    mysql-server \
    nginx \
    openssh-blacklist \
    openssl-blacklist \
    php5 \
    php5-common \
    php5-curl \
    php5-dev \
    php5-gd \
    php5-imagick \
    php5-mcrypt \
    php5-memcache \
    php5-mysql \
    screen \
    subversion \
    telnet \
    vim-full \
    wget \
    zsh
    
# Initialize the 'locate' database.
updatedb




