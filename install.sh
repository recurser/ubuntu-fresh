#!/usr/bin/env bash

# Function for confirming choices with the user.
function confirm() {
    read -p "$@ [Y/n]" answer
    for response in n N no No NO; do
        if [ "_$answer" == "_$response" ]; then
            return 0
        fi
    done
    
    return 1
}

# Get the current directory.
CURR_DIR=$(cd `dirname $0` && pwd)


#--------------------------------------------------------------------
#
# R E A D   I N   I N I T I A L   U S E R   D A T A
#
#--------------------------------------------------------------------


echo
echo
echo "#############################################################"
echo "#                                                           #"
echo "#        C O L L E C T I N G   I N F O R M A T I O N        #"
echo "#                                                           #"
echo "#  We need to collect some information about you before we  #"
echo "#  begin. This will be used to set up a default user,       #"
echo "#  hostname, and set your user's details in git.            #"
echo "#                                                           #"
echo "#############################################################"
echo

# Read in the user name.
while [ -z "$NEW_USER" ]; do
    read -p "What username would you like to use? " NEW_USER
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
sudo apt-get update -y
sudo apt-get upgrade -y

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
    php5-cli \
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
    ssh-server \
    ssl-cert \
    subversion \
    subversion-tools \
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
    sudo su root -c "echo -n \"PermitRootLogin no\n\" >> /etc/ssh/sshd_config"
fi
if [ `grep X11Forwarding /etc/ssh/sshd_config | wc -l` -eq 0 ]; then
    sudo su root -c "echo \"X11Forwarding no\" >> /etc/ssh/sshd_config"
fi
if [ `grep UsePAM /etc/ssh/sshd_config | wc -l` -eq 0 ]; then
    sudo su root -c "echo \"UsePam no\" >> /etc/ssh/sshd_config"
fi
if [ `grep UseDNS /etc/ssh/sshd_config | wc -l` -eq 0 ]; then
        sudo su root -c "echo \"UseDNS no\" >> /etc/ssh/sshd_config"
fi;
if [ `grep AllowUsers /etc/ssh/sshd_config | wc -l` -eq 0 ]; then
        sudo su root -c "echo \"AllowUsers ${NEW_USER}\" >> /etc/ssh/sshd_config"
fi;


#--------------------------------------------------------------------
#
# H O S T N A M E
#
#--------------------------------------------------------------------
sudo sed -ri "s|^127\.0\.0\.1 localhost.*$|127.0.0.1 localhost ${DOMAIN}|" /etc/hosts
sudo /bin/hostname $  


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
if [ $(which gem | wc -l) -eq 0 ]; then
    install_rubygems=1
fi
if [ `gem --version` != "1.7.2" ]; then
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
    rdoc \
    rvm \
    rake
    
# Setup rvm.
sudo su root -c "bash < <(curl -s -B https://rvm.beginrescueend.com/install/rvm)"


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
    sudo su root -c "echo \"Listen 8080\" > /etc/apache2/ports.conf"
    sudo cp ${CURR_DIR}/conf/apache-default.conf /etc/apache2/sites-available/default
    sudo cp ${CURR_DIR}/conf/apache-domain.conf /etc/apache2/sites-available/${DOMAIN}
    sudo ln -s /etc/apache2/sites-available/${DOMAIN} /etc/apache2/sites-enabled/001-${DOMAIN}
    sudo sed -ri "s|__DOMAIN__|${DOMAIN}|g" /etc/apache2/sites-available/${DOMAIN}
    sudo sed -ri "s|__DOMAIN__|${DOMAIN}|g" /etc/apache2/sites-available/default
    # Put our default at last instead of first.
    sudo rm -f /etc/apache2/sites-enabled/000-default /etc/apache2/sites-enabled/999-default
    sudo ln -s /etc/apache2/sites-available/default /etc/apache2/sites-enabled/999-default
    # Set up DocumentRoot
    sudo mkdir -p /var/www/${DOMAIN}/
    sudo cp ${CURR_DIR}/conf/index.html /var/www/${DOMAIN}/
    sudo sed -ri "s|__DOMAIN__|${DOMAIN}|g" /var/www/${DOMAIN}/index.html
    sudo chown -R www-data:www-data /var/www/${DOMAIN}/
    sudo chmod -R g+w /var/www/${DOMAIN}/
    # Add phpinfo() just for kicks :)
    sudo su root -c "echo \"<?= phpinfo() ?>\" > /var/www/${DOMAIN}/info.php"
    
    sudo /etc/init.d/apache2 restart
fi


#--------------------------------------------------------------------
#
# N G I N X
#
#--------------------------------------------------------------------
if [ ! -f /etc/nginx/sites-available/${DOMAIN} ]; then
    sudo cp ${CURR_DIR}/conf/nginx-default.conf /etc/nginx/sites-available/default
    sudo cp ${CURR_DIR}/conf/nginx-domain.conf /etc/nginx/sites-available/${DOMAIN}
    sudo ln -s /etc/nginx/sites-available/${DOMAIN} /etc/nginx/sites-enabled/001-${DOMAIN}
    sudo sed -ri "s|__DOMAIN__|${DOMAIN}|g" /etc/nginx/sites-available/${DOMAIN}
    sudo sed -ri "s|__DOMAIN__|${DOMAIN}|g" /etc/nginx/sites-available/default
    # Unlike apache, default config doesn't ship with a numeric prefix for some reason - fix this.
    if [ -f /etc/nginx/sites-enabled/default ]; then
        sudo mv /etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/000-default
    fi
    
    # Make SSL certificate.
    echo
    echo
    echo "#############################################################"
    echo "#                                                           #"
    echo "#               S S L   C E R T I F I C A T E               #"
    echo "#                                                           #"
    echo "#  Next we're going to create an SSL certificate for your   #"
    echo "#  site, so you can accept secure HTTPS connections. You'll #"
    echo "#  need to enter a passphrase for you private key below -   #"
    echo "#  you may need it in the future so don't forget it!        #"
    echo "#                                                           #"
    echo "#############################################################"
    echo
    
    sudo mkdir -p /etc/nginx/certificates/signed
    sudo mkdir -p /etc/nginx/certificates/private
    rm -f ${DOMAIN}.csr ${DOMAIN}.key ${DOMAIN}.crt
    openssl genrsa -des3 -out ${DOMAIN}.key 1024
    openssl req -new -nodes -keyout ${DOMAIN}.key -out ${DOMAIN}.csr
    openssl x509 -req -days 365 -in ${DOMAIN}.csr -signkey ${DOMAIN}.key -out ${DOMAIN}.crt
    sudo mv ${DOMAIN}.crt /etc/nginx/certificates/signed/${DOMAIN}.crt
    sudo mv ${DOMAIN}.key /etc/nginx/certificates/private/${DOMAIN}.key
    
    sudo /etc/init.d/nginx restart
fi


#--------------------------------------------------------------------
#
# S U B V E R S I O N
#
#--------------------------------------------------------------------


echo
echo
echo "#############################################################"
echo "#                                                           #"
echo "#            S U B V E R S I O N   H O S T I N G            #"
echo "#                                                           #"
echo "#  We can set up the server to host subversion repositories #"
echo "#  if you wish. If you are not sure, choose 'n'.            #"
echo "#                                                           #"
echo "###############################################################"
echo

ADD_SVN=0
confirm "Would you like this server to host subversion repositories (http://${DOMAIN}/svn/)?"
if [ $? -eq 1 ]; then
    ADD_SVN=1
fi
if [ $ADD_SVN -eq 1 ]; then
    sudo mkdir -p /opt/subversion/repositories
    # Apache config - over-write regular config with svn-specific one.
    sudo cp ${CURR_DIR}/conf/apache-svn.conf /etc/apache2/sites-available/${DOMAIN}
    sudo sed -ri "s|__DOMAIN__|${DOMAIN}|g" /etc/apache2/sites-available/${DOMAIN}
    # Access policy.
    sudo cp ${CURR_DIR}/conf/access.policy /opt/subversion/access.policy
    sudo sed -ri "s|__USER__|${NEW_USER}|g" /opt/subversion/access.policy
    # Create passwords file if necessary.
    sudo touch /opt/subversion/passwords
    echo "Please enter a password for the first subversion user (${NEW_USER}) - you can add others later:"
    sudo htpasswd /opt/subversion/passwords ${NEW_USER}
    # Make a new empty repository to hold the repos-style stuff.
    REPO_NAME=repos-web
    sudo rm -Rf /opt/subversion/repositories/${REPO_NAME}
    sudo svnadmin create --fs-type fsfs /opt/subversion/repositories/${REPO_NAME}
    sudo chmod -R g+w /opt/subversion/repositories/${REPO_NAME}
    sudo chmod g+s /opt/subversion/repositories/${REPO_NAME}/db
    # Set up repos-style in a new repository to make things look a bit nicer, and give us an example repository.
    cd /tmp
    sudo rm -Rf repos-web
    sudo svn co https://labs.repos.se/data/style/tags/2.4/repos-web/
    sudo find repos-web -name .svn -exec rm -Rf {} \; > /dev/null 2>&1;
    sudo tar czf repos-web.tar.gz repos-web
    sudo rm -Rf repos-web
    sudo svn co file:///opt/subversion/repositories/repos-web
    sudo tar xzf repos-web.tar.gz
    cd repos-web
    sudo svn stat | grep '?       ' | awk '{ print $2 }' | xargs svn add
    sudo sed -ri 's|<xsl:param name="static">/repos-web/</xsl:param>|<xsl:param name="static">/svn/repos-web/</xsl:param>|' view/repos.xsl
    sudo sed -ri 's|<xsl:param name="startpage">/</xsl:param>|<xsl:param name="startpage">/svn/</xsl:param>|' view/repos.xsl
    sudo svn commit -m "Initial commit."
    sudo find . -name "*.xsl" -exec svn propset svn:mime-type text/xsl {} \;
    sudo svn commit -m "Fixed some mime-type issues for XSL."
    cd ../
    sudo rm -Rf repos-web.tar.gz repos-web
    # Make a private repository to demonstrate the access control.
    REPO_NAME=private-repo
    sudo rm -Rf /opt/subversion/repositories/${REPO_NAME}
    sudo svnadmin create --fs-type fsfs /opt/subversion/repositories/${REPO_NAME}
    sudo chmod -R g+w /opt/subversion/repositories/${REPO_NAME}
    sudo chmod g+s /opt/subversion/repositories/${REPO_NAME}/db
    # Fix permissions.
    sudo chown -R www-data:www-data /opt/subversion
    # Restart apache and nginx.
    sudo /etc/init.d/apache2 restart
fi


echo
echo
echo "#############################################################"
echo "#                                                           #"
echo "#                   G I T   H O S T I N G                   #"
echo "#                                                           #"
echo "#  We can set up the server to host git repositories if you #"
echo "#  wish. If you are not sure, choose 'n'.                   #"
echo "#                                                           #"
echo "###############################################################"
echo

ADD_GIT=0
confirm "Would you like this server to host git repositories (http://${DOMAIN}/svn/)?"
if [ $? -eq 1 ]; then
    ADD_GIT=1
fi
if [ $ADD_GIT -eq 1 ]; then
  # Add a 'git' user.
  cd /tmp
  rm -Rf home-config
  git clone git://github.com/recurser/home-config.git
  cd home-config
  sudo ./install.sh git
  
  cd /tmp/
  git clone git://github.com/sitaramc/gitolite.git
  cd gitolite
  make master.tar
fi
