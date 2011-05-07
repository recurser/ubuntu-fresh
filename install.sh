#!/usr/bin/env sh


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
    exuberant-ctags \
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
    ruby \
    ruby-dev \
    screen \
    subversion \
    telnet \
    vim \
    vim-perl \
    vim-python \
    vim-rails \
    vim-ruby \
    wget \
    zsh
    
# Initialize the 'locate' database.
sudo updatedb


#--------------------------------------------------------------------
#
# I N S T A L L   G E M S
#
#--------------------------------------------------------------------
if [ $(which gem | wc -l) -eq 0 -o `gem --version` != "1.7.2" ]; then
    cd /tmp
    wget http://production.cf.rubygems.org/rubygems/rubygems-1.7.2.tgz
    tar xvzf rubygems-1.7.2.tgz
    cd rubygems-1.7.2
    sudo ruby setup.rb
    sudo ln -s /usr/bin/gem1.8 /usr/bin/gem
fi

sudo gem install --no-rdoc --no-ri \
    bundler \
    capistrano \
    git-up \
    rvm \
    rake
    
# Setup rvm
su root -c "bash < <(curl -s -B https://rvm.beginrescueend.com/install/rvm)"


#--------------------------------------------------------------------
#
# S E T   U P   U S E R   A C C O U N T
#
#--------------------------------------------------------------------
if [ `grep $user /etc/passwd | wc -l` -eq 0 ]; then
    echo "\n\n Adding a new user '$user' - please enter a password at the prompt."
    sudo adduser --home /users/$user $user
    mkdir -p /users/$user
    chown $user:$user /users/$user
    
    # Set up zsh and vim config etc.
    chsh -s /usr/bin/zsh $user
    cd /tmp
    rm -Rf home-config
    git clone git://github.com/recurser/home-config.git
    cd home-config
    sudo ./install.sh $user
fi;

# Make zsh the default shell.
if ! id $user > /dev/null 2>&1; then
    chsh user /usr/bin/zsh
fi


