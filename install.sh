#!/usr/bin/env bash

CURR_DIR=$(cd `dirname $0` && pwd)



#--------------------------------------------------------------------
#
# S U B V E R S I O N
#
#--------------------------------------------------------------------
if [ ! -f /etc/nginx/sites-available/svn.${DOMAIN} ]; then
    ADD_SVN=0
    read -p "Would you like this server to host subversion repositories (svn.${DOMAIN})? [y/N] " SVN_CHOICE
    if [ $SVN_CHOICE == 'Y' -o $SVN_CHOICE == 'y' ]; then
        ADD_SVN=1
    fi
    if [ $ADD_SVN -eq 1 ]; then
        sudo mkdir -p /opt/subversion/repositories
        # Apache config.
        sudo cp ${CURR_DIR}/conf/apache-svn.conf /etc/apache2/sites-available/svn.${DOMAIN}
        sudo ln -s /etc/apache2/sites-available/svn.${DOMAIN} /etc/apache2/sites-enabled/002-svn.${DOMAIN}
        sudo sed -ri "s|__DOMAIN__|${DOMAIN}|g" /etc/apache2/sites-available/svn.${DOMAIN}
        # Access policy.
        sudo cp ${CURR_DIR}/conf/access.policy /opt/subversion/access.policy
        # Create empty passwords file.
        sudo touch /opt/subversion/passwords
        # Restart apache.
        sudo /etc/init.d/apache2 restart
    fi
fi

exit

#--------------------------------------------------------------------
#
# R E A D   I N   I N I T I A L   U S E R   D A T A
#
#--------------------------------------------------------------------

# Read in the user name.
while [ -z "$NEW_USER" ]; do
    read -p "What username would you like to use? " user
done

# Read in the domain name.
while [ -z "$DOMAIN" ]; do
    read -p "What domain would you like to access your server with? " DOMAIN
done

# Read in the full name.
while [ -z "$FULL_NAME" ]; do
    read -p "What is your full name? " FULL_NAME
done

# Read in the full email address.
while [ -z "$EMAIL" ]; do
    read -p "What is your email address? " EMAIL
done


#--------------------------------------------------------------------
#
# S E T   U P   G I T   N A M E   A N D   E M A I L
#
#--------------------------------------------------------------------
if [ `git config --global --get user.name | wc -l` -eq 0 ]; then
    git config --global user.name $FULL_NAME
fi

if [ `git config --global --get user.email | wc -l` -eq 0 ]; then
    git config --global user.email $EMAIL
fi


#--------------------------------------------------------------------
#
# I N S T A L L   B A S E   P A C K A G E S
#
#--------------------------------------------------------------------
sudo apt-get update
sudo apt-get upgrade

sudo aptitude install -y \
    apache2 \
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
    libapache2-svn \
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
    php-apc \
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
    rvm \
    screen \
    ssl-cert \
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
# S S H   C O N F I G
#
#--------------------------------------------------------------------
sudo sed -ri "s|PermitRootLogin yes|PermitRootLogin no|" /etc/ssh/sshd_config
sudo sed -ri "s|X11Forwarding yes|X11Forwarding no|" /etc/ssh/sshd_config
sudo sed -ri "s|UseDNS yes|UseDNS no|" /etc/ssh/sshd_config
sudo sed -ri "s|UsePAM yes|UsePAM no|" /etc/ssh/sshd_config
if [ `grep PermitRootLogin /etc/ssh/sshd_config | wc -l` -eq 0 ]; then
    su root -c "echo -n \"PermitRootLogin no\n\" >> /etc/ssh/sshd_config"
fi
if [ `grep X11Forwarding /etc/ssh/sshd_config | wc -l` -eq 0 ]; then
    su root -c "echo \"X11Forwarding no\" >> /etc/ssh/sshd_config"
fi
if [ `grep UsePAM /etc/ssh/sshd_config | wc -l` -eq 0 ]; then
    su root -c "echo \"UsePam no\" >> /etc/ssh/sshd_config"
fi
if [ `grep UseDNS /etc/ssh/sshd_config | wc -l` -eq 0 ]; then
        su root -c "echo \"UseDNS no\" >> /etc/ssh/sshd_config"
fi;
if [ `grep AllowUsers /etc/ssh/sshd_config | wc -l` -eq 0 ]; then
        su root -c "echo \"AllowUsers ${NEW_USER}\" >> /etc/ssh/sshd_config"
fi;


#--------------------------------------------------------------------
#
# H O S T N A M E
#
#--------------------------------------------------------------------
sudo /bin/hostname $DOMAIN
sudo sed -ri "s|^127\.0\.0\.1 localhost.*$|127.0.0.1 localhost ${DOMAIN}|" /etc/hosts


#--------------------------------------------------------------------
#
# I P T A B L E S   R U L E S
#
#--------------------------------------------------------------------
if [ ! -f /etc/iptables.up.rules ]; then
    sudo iptables-restore < conf/iptables.up.rules
    sudo cp ${CURR_DIR}/conf/iptables.up.rules /etc/iptables.up.rules
fi
if [ `grep iptables-restore /etc/network/interfaces | wc -l` -eq 0 ]; then
    sudo sed -ri "s|iface lo inet loopback|iface lo inet loopback\npre-up iptables-restore < /etc/iptables.up.rules|" /etc/network/interfaces
    sudo /etc/init.d/ssh reload
fi


#--------------------------------------------------------------------
#
# I N S T A L L   G E M S
#
#--------------------------------------------------------------------
install_rubygems=0
if [ $(which gem | wc -l) -eq 0 ]: thn
    install_rubygems=1
elsif [ `gem --version` != "1.7.2" ]; then
    install_rubygems=1
fi

if [ $install_rubygems -eq 1 ]; then
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
    
# Setup rvm.
su root -c "bash < <(curl -s -B https://rvm.beginrescueend.com/install/rvm)"


#--------------------------------------------------------------------
#
# S E T   U P   U S E R   A C C O U N T
#
#--------------------------------------------------------------------
if [ `grep $NEW_USER /etc/passwd | wc -l` -eq 0 ]; then
    cd /tmp
    rm -Rf home-config
    git clone git://github.com/recurser/home-config.git
    cd home-config
    sudo ./install.sh $NEW_USER
fi;


#--------------------------------------------------------------------
#
# A P A C H E
#
#--------------------------------------------------------------------
if [ ! -f /etc/apache2/sites-available/${DOMAIN} ]; then
    su root -c "echo \"Listen 8080\" > /etc/apache2/ports.conf"
    sudo cp ${CURR_DIR}/conf/apache-default.conf /etc/apache2/sites-available/default
    sudo cp ${CURR_DIR}/conf/apache-domain.conf /etc/apache2/sites-available/${DOMAIN}
    sudo ln -s /etc/apache2/sites-available/${DOMAIN} /etc/apache2/sites-enabled/001-${DOMAIN}
    sudo sed -ri "s|__DOMAIN__|${DOMAIN}|g" /etc/apache2/sites-available/${DOMAIN}
    sudo sed -ri "s|__DOMAIN__|${DOMAIN}|g" /etc/apache2/sites-available/default
    
    sudo mkdir -p /var/www/${DOMAIN}/
    sudo cp ${CURR_DIR}/conf/index.html /var/www/${DOMAIN}/
    sudo sed -ri "s|__DOMAIN__|${DOMAIN}|g" /var/www/${DOMAIN}/index.html
    
    sudo /etc/init.d/apache2 restart
fi


#--------------------------------------------------------------------
#
# N G I N X
#
#--------------------------------------------------------------------
if [ ! -f /etc/nginx/sites-available/${DOMAIN} ]; then
    sudo cp ${CURR_DIR}/conf/nginx-domain.conf /etc/nginx/sites-available/${DOMAIN}
    sudo ln -s /etc/nginx/sites-available/${DOMAIN} /etc/nginx/sites-enabled/001-${DOMAIN}
    sudo sed -ri "s|__DOMAIN__|${DOMAIN}|g" /etc/nginx/sites-available/${DOMAIN}
    
    # Unlike apache, default config doesn't ship with a numeric prefix for some reason - fix this.
    if [ -f /etc/nginx/sites-enabled/default ]; then
        sudo mv /etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/000-default
    fi
    
    # Make SSL certificate.
    sudo mkdir -p /etc/nginx/certificates/signed
    sudo mkdir -p /etc/nginx/certificates/private
    rm -f ${DOMAIN}.csr ${DOMAIN}.key ${DOMAIN}.crt
    openssl genrsa -des3 -out ${DOMAIN}.key 1024
    openssl req -new -key ${DOMAIN}.key -out ${DOMAIN}.csr
    mv ${DOMAIN}.key ${DOMAIN}.key.orig
    openssl rsa -in ${DOMAIN}.key.orig -out ${DOMAIN}.key
    rm ${DOMAIN}.key.orig
    openssl x509 -req -days 365 -in ${DOMAIN}.csr -signkey ${DOMAIN}.key -outform CRT -out ${DOMAIN}.crt
    sudo mv ${DOMAIN}.crt /etc/nginx/certificates/signed/${DOMAIN}.crt
    sudo mv ${DOMAIN}.key /etc/nginx/certificates/private/${DOMAIN}.key
    
    sudo /etc/init.d/nginx restart
fi