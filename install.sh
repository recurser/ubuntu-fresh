#!/usr/bin/env bash

# Make sure we're running as root.
if [ $USER != 'root' ]; then
  echo "This script must be run as the 'root' user."
  exit
fi

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
apt-get update -y
apt-get upgrade -y

aptitude install -y \
    apache2 \
    build-essential \
    curl \
    exuberant-ctags \
    fail2ban \
    fakeroot \
    gcc \
    locales \
    language-pack-en \
    language-pack-ja \
    libapache2-mod-php5 \
    libapache2-mod-suphp \
    libapache2-mod-rpaf \
    libapache2-svn \
    locate \
    memcached \
    mercurial \
    mysql-client\
    mysql-common \
    mysql-server \
    nginx \
    openssh-blacklist \
    openssh-server \
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
    ssh \
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
updatedb


#--------------------------------------------------------------------
#
# S S H   C O N F I G
#
#--------------------------------------------------------------------
sed -ri "s|PermitRootLogin yes|PermitRootLogin no|" /etc/ssh/sshd_config
sed -ri "s|X11Forwarding yes|X11Forwarding no|" /etc/ssh/sshd_config
sed -ri "s|UseDNS yes|UseDNS no|" /etc/ssh/sshd_config
sed -ri "s|UsePAM yes|UsePAM no|" /etc/ssh/sshd_config
if [ `grep PermitRootLogin /etc/ssh/sshd_config | wc -l` -eq 0 ]; then
    echo -n "PermitRootLogin no\n" >> /etc/ssh/sshd_config
fi
if [ `grep X11Forwarding /etc/ssh/sshd_config | wc -l` -eq 0 ]; then
    echo "X11Forwarding no" >> /etc/ssh/sshd_config
fi
if [ `grep UsePAM /etc/ssh/sshd_config | wc -l` -eq 0 ]; then
    echo "UsePam no" >> /etc/ssh/sshd_config
fi
if [ `grep UseDNS /etc/ssh/sshd_config | wc -l` -eq 0 ]; then
        echo "UseDNS no" >> /etc/ssh/sshd_config
fi;
if [ `grep AllowUsers /etc/ssh/sshd_config | wc -l` -eq 0 ]; then
        echo "AllowUsers ${NEW_USER}" >> /etc/ssh/sshd_config
fi;


#--------------------------------------------------------------------
#
# H O S T N A M E
#
#--------------------------------------------------------------------
sed -ri "s|^127\.0\.0\.1[\s\t]+localhost.*$|127.0.0.1 localhost ${DOMAIN}|" /etc/hosts
/bin/hostname $DOMAIN


#--------------------------------------------------------------------
#
# I P T A B L E S   R U L E S
#
#--------------------------------------------------------------------
if [ ! -f /etc/iptables.up.rules ]; then
    iptables-restore < conf/iptables.up.rules
    cp ${CURR_DIR}/conf/iptables.up.rules /etc/iptables.up.rules
fi
if [ `grep iptables-restore /etc/network/interfaces | wc -l` -eq 0 ]; then
    sed -ri "s|iface lo inet loopback|iface lo inet loopback\npre-up iptables-restore < /etc/iptables.up.rules|" /etc/network/interfaces
    /etc/init.d/ssh reload
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
    ruby setup.rb
    ln -s /usr/bin/gem1.8 /usr/bin/gem
fi

gem install --no-rdoc --no-ri \
    bundler \
    capistrano \
    git-up \
    rdoc \
    rvm \
    rake
    
# Setup rvm.
bash < <(curl -s -B https://rvm.beginrescueend.com/install/rvm)


#--------------------------------------------------------------------
#
# S E T   U P   U S E R   A C C O U N T
#
#--------------------------------------------------------------------
cd /tmp
rm -Rf home-config
git clone git://github.com/recurser/home-config.git
cd home-config
./install.sh $NEW_USER


#--------------------------------------------------------------------
#
# A P A C H E
#
#--------------------------------------------------------------------
if [ ! -f /etc/apache2/sites-available/${DOMAIN} ]; then
    echo "Listen 8080" > /etc/apache2/ports.conf
    cp ${CURR_DIR}/conf/apache-default.conf /etc/apache2/sites-available/default
    cp ${CURR_DIR}/conf/apache-domain.conf /etc/apache2/sites-available/${DOMAIN}
    ln -s /etc/apache2/sites-available/${DOMAIN} /etc/apache2/sites-enabled/001-${DOMAIN}
    sed -ri "s|__DOMAIN__|${DOMAIN}|g" /etc/apache2/sites-available/${DOMAIN}
    sed -ri "s|__DOMAIN__|${DOMAIN}|g" /etc/apache2/sites-available/default
    # Put our default at last instead of first.
    rm -f /etc/apache2/sites-enabled/000-default /etc/apache2/sites-enabled/999-default
    ln -s /etc/apache2/sites-available/default /etc/apache2/sites-enabled/999-default
    # Set up DocumentRoot
    mkdir -p /var/www/${DOMAIN}/
    cp ${CURR_DIR}/conf/index.html /var/www/${DOMAIN}/
    sed -ri "s|__DOMAIN__|${DOMAIN}|g" /var/www/${DOMAIN}/index.html
    chown -R www-data:www-data /var/www/${DOMAIN}/
    chmod -R g+w /var/www/${DOMAIN}/
    # Add phpinfo() just for kicks :)
    echo "<?= phpinfo() ?>" > /var/www/${DOMAIN}/info.php
    
    # Enable mod_rewrite
    a2enmod rewrite headers expires
    
    /etc/init.d/apache2 restart
fi


#--------------------------------------------------------------------
#
# N G I N X
#
#--------------------------------------------------------------------
if [ ! -f /etc/nginx/sites-available/${DOMAIN} ]; then
    cp ${CURR_DIR}/conf/nginx-default.conf /etc/nginx/sites-available/default
    cp ${CURR_DIR}/conf/nginx-domain.conf /etc/nginx/sites-available/${DOMAIN}
    ln -s /etc/nginx/sites-available/${DOMAIN} /etc/nginx/sites-enabled/001-${DOMAIN}
    sed -ri "s|__DOMAIN__|${DOMAIN}|g" /etc/nginx/sites-available/${DOMAIN}
    sed -ri "s|__DOMAIN__|${DOMAIN}|g" /etc/nginx/sites-available/default
    # Unlike apache, default config doesn't ship with a numeric prefix for some reason - fix this.
    if [ -f /etc/nginx/sites-enabled/default ]; then
        mv /etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/000-default
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
    
    mkdir -p /etc/nginx/certificates/signed
    mkdir -p /etc/nginx/certificates/private
    rm -f ${DOMAIN}.csr ${DOMAIN}.key ${DOMAIN}.crt
    openssl genrsa -des3 -out ${DOMAIN}.key 1024
    openssl req -new -nodes -keyout ${DOMAIN}.key -out ${DOMAIN}.csr
    openssl x509 -req -days 365 -in ${DOMAIN}.csr -signkey ${DOMAIN}.key -out ${DOMAIN}.crt
    mv ${DOMAIN}.crt /etc/nginx/certificates/signed/${DOMAIN}.crt
    mv ${DOMAIN}.key /etc/nginx/certificates/private/${DOMAIN}.key
    
    /etc/init.d/nginx restart
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
echo "#############################################################"
echo

ADD_SVN=0
confirm "Would you like this server to host subversion repositories (http://${DOMAIN}/svn/)?"
if [ $? -eq 1 ]; then
    ADD_SVN=1
fi
if [ $ADD_SVN -eq 1 ]; then
    mkdir -p /opt/subversion/repositories
    # Apache config - over-write regular config with svn-specific one.
    cp ${CURR_DIR}/conf/apache-svn.conf /etc/apache2/sites-available/${DOMAIN}
    sed -ri "s|__DOMAIN__|${DOMAIN}|g" /etc/apache2/sites-available/${DOMAIN}
    # Access policy.
    cp ${CURR_DIR}/conf/access.policy /opt/subversion/access.policy
    sed -ri "s|__USER__|${NEW_USER}|g" /opt/subversion/access.policy
    # Create passwords file if necessary.
    touch /opt/subversion/passwords
    echo "Please enter a password for the first subversion user (${NEW_USER}) - you can add others later:"
    htpasswd /opt/subversion/passwords ${NEW_USER}
    # Make a new empty repository to hold the repos-style stuff.
    REPO_NAME=repos-web
    rm -Rf /opt/subversion/repositories/${REPO_NAME}
    svnadmin create --fs-type fsfs /opt/subversion/repositories/${REPO_NAME}
    chmod -R g+w /opt/subversion/repositories/${REPO_NAME}
    chmod g+s /opt/subversion/repositories/${REPO_NAME}/db
    # Set up repos-style in a new repository to make things look a bit nicer, and give us an example repository.
    cd /tmp
    rm -Rf repos-web
    svn co https://labs.repos.se/data/style/tags/2.4/repos-web/
    find repos-web -name .svn -exec rm -Rf {} \; > /dev/null 2>&1;
    tar czf repos-web.tar.gz repos-web
    rm -Rf repos-web
    svn co file:///opt/subversion/repositories/repos-web
    tar xzf repos-web.tar.gz
    cd repos-web
    svn stat | grep '?       ' | awk '{ print $2 }' | xargs svn add
    sed -ri 's|<xsl:param name="static">/repos-web/</xsl:param>|<xsl:param name="static">/svn/repos-web/</xsl:param>|' view/repos.xsl
    sed -ri 's|<xsl:param name="startpage">/</xsl:param>|<xsl:param name="startpage">/svn/</xsl:param>|' view/repos.xsl
    svn commit -m "Initial commit."
    find . -name "*.xsl" -exec svn propset svn:mime-type text/xsl {} \;
    svn commit -m "Fixed some mime-type issues for XSL."
    cd ../
    rm -Rf repos-web.tar.gz repos-web
    # Make a private repository to demonstrate the access control.
    REPO_NAME=private-repo
    rm -Rf /opt/subversion/repositories/${REPO_NAME}
    svnadmin create --fs-type fsfs /opt/subversion/repositories/${REPO_NAME}
    chmod -R g+w /opt/subversion/repositories/${REPO_NAME}
    chmod g+s /opt/subversion/repositories/${REPO_NAME}/db
    # Fix permissions.
    chown -R www-data:www-data /opt/subversion
    # Restart apache and nginx.
    /etc/init.d/apache2 restart
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
echo "#############################################################"
echo

ADD_GIT=0
confirm "Would you like this server to host git repositories?"
if [ $? -eq 1 ]; then
    ADD_GIT=1
fi
if [ $ADD_GIT -eq 1 ]; then
    # Add a 'git' user.
    GIT_USER=git
    cd /tmp
    rm -Rf home-config
    git clone git://github.com/recurser/home-config.git
    cd home-config
    ./install.sh $GIT_USER
    
    # Make sure the git user is alllowed to SSH.
    if [ `grep "AllowUsers.*git" /etc/ssh/sshd_config | wc -l` -eq 0 ]; then
        sed -ri "s|^(AllowUsers.*)$|\1 ${GIT_USER}|" /etc/ssh/sshd_config
        /etc/init.d/ssh restart
    fi;
    
    # Get the home directory of the git user.
    su $GIT_USER -c "echo \$HOME" > /tmp/${GIT_USER}_HOME
    GIT_USER_HOME=`cat /tmp/${GIT_USER}_HOME`
    rm /tmp/${GIT_USER}_HOME
    
    # Add the gitolite path for the git user's zsh profile.
    touch ${GIT_USER_HOME}/.zshrc.local
    if [ `grep /opt/bin/gitolite ${GIT_USER_HOME}/.zshrc.local | wc -l` -eq 0 ]; then
        echo "PATH=/opt/gitolite/bin:\$PATH" >> ${GIT_USER_HOME}/.zshrc.local
    fi
    chown ${GIT_USER}:${GIT_USER} ${GIT_USER_HOME}/.zshrc.local
    
    # Add the gitolite path for the git user's bash profile.
    touch ${GIT_USER_HOME}/.bash_profile
    if [ `grep /opt/bin/gitolite ${GIT_USER_HOME}/.bash_profile | wc -l` -eq 0 ]; then
        echo "PATH=/opt/gitolite/bin:\$PATH" >> ${GIT_USER_HOME}/.bash_profile
    fi
    chown ${GIT_USER}:${GIT_USER} ${GIT_USER_HOME}/.bash_profile
    
    # Copy NEW_USER's public key to /tmp/.
    su $NEW_USER -c "echo \$HOME" > /tmp/${NEW_USER}_HOME
    NEW_USER_HOME=`cat /tmp/${NEW_USER}_HOME`
    rm /tmp/${NEW_USER}_HOME
    cp ${NEW_USER_HOME}/.ssh/id_rsa.pub /tmp/${NEW_USER}.pub
    
    # Install gitolite server.
    cd /tmp/
    rm -Rf gitolite-source
    git clone git://github.com/sitaramc/gitolite gitolite-source
    cd gitolite-source
    mkdir -p /opt/gitolite/conf /opt/gitolite/hooks
    src/gl-system-install /opt/gitolite/bin /opt/gitolite/conf /opt/gitolite/hooks
    chown -R git:git /opt/gitolite    
    su $GIT_USER -c "PATH=/opt/gitolite/bin:\$PATH && /opt/gitolite/bin/gl-setup -q /tmp/${NEW_USER}.pub"
    
    # Install gitolite admin client.
    su $NEW_USER -c "git clone git@${DOMAIN}:gitolite-admin.git ~/gitolite-admin"
    
    # Install git-daemon.
    aptitude install git-daemon-run
    sed -ri "s|exec chpst -ugitdaemon |exec chpst -ugitdaemon:gitolite |" /etc/sv/git-daemon/run
    sed -ri "s|--base-path=/var/cache /var/cache/git|--base-path=${GIT_USER_HOME}/repositories ${GIT_USER_HOME}/repositories|" /etc/sv/git-daemon/run
    cp ${CURR_DIR}/conf/git-daemon /etc/init.d/git-daemon
    chmod a+x /etc/init.d/git-daemon
    /usr/sbin/update-rc.d git-daemon defaults
fi


echo
echo
echo "#############################################################"
echo "#                                                           #"
echo "#                 E M A I L   S E N D I N G                 #"
echo "#                                                           #"
echo "#  We can set up the server to send email via gmail if you  #"
echo "#  wish. This will require storing your gmail address and   #"
echo "#  password on the server in plain text. If you are not     #"
echo "#  sure, choose 'n'.                                        #"
echo "#                                                           #"
echo "# You can also use a non-@gmail.com address if as long as   #"
echo "# it is set up through google apps for domains.             #"
echo "#                                                           #"
echo "#############################################################"
echo

ADD_GMAIL=0
confirm "Would you like this server to send mail via your gmail account?"
if [ $? -eq 1 ]; then
    ADD_GMAIL=1
fi
if [ $ADD_GMAIL -eq 1 ]; then

    # Read in the gmail email address.
    while [ -z "$GMAIL_USER" ]; do
        read -p "What gmail address would you like to send email from? Please include @gmail.com. " GMAIL_USER
    done

    # Read in the gmail email address.
    while [ -z "$GMAIL_NAME" ]; do
        read -p "What name would you like the email to be associated with? " GMAIL_NAME
    done

    # Read in the gmail password.
    while [ -z "$GMAIL_PASS" ]; do
        read -p "What is the password for that account? " GMAIL_PASS
    done
    
    aptitude install sendmail
    
    if [ ! -f /etc/mail/sendmail.mc.orig ]; then
        cp /etc/mail/sendmail.mc /etc/mail/sendmail.mc.orig
    fi
    
    if [ `grep smtp.gmail.com /etc/mail/sendmail.mc | wc -l` -eq 0 ]; then
        sed -ri "s|MAILER_DEFINITIONS|FEATURE(\`authinfo',\`hash /etc/mail/auth/client-info')dnl\nMAILER_DEFINITIONS|g" /etc/mail/sendmail.mc
        echo -n "\n" >> /etc/mail/sendmail.mc
        echo -n "define(\`SMART_HOST',\`smtp.gmail.com')dnl\n" >> /etc/mail/sendmail.mc
        echo -n "define(\`confAUTH_MECHANISMS', \`EXTERNAL GSSAPI DIGEST-MD5 CRAM-MD5 LOGIN PLAIN')dnl\n" >> /etc/mail/sendmail.mc
        echo -n "define(\`CERT_DIR', \`MAIL_SETTINGS_DIR\`'certs')\n" >> /etc/mail/sendmail.mc
        echo -n "define(\`confCACERT_PATH', \`CERT_DIR')\n" >> /etc/mail/sendmail.mc
        echo -n "define(\`confCACERT_PATH', \`CERT_DIR')\n" >> /etc/mail/sendmail.mc
        echo -n "define(\`confCACERT', \`CERT_DIR/CAcert.pem')\n" >> /etc/mail/sendmail.mc
        echo -n "define(\`confSERVER_CERT', \`CERT_DIR/gmailcert.pem')\n" >> /etc/mail/sendmail.mc
        echo -n "define(\`confSERVER_KEY', \`CERT_DIR/gmailkey.pem')\n" >> /etc/mail/sendmail.mc
        echo -n "define(\`confCLIENT_CERT', \`CERT_DIR/gmailcert.pem')\n" >> /etc/mail/sendmail.mc
        echo -n "define(\`confCLIENT_KEY', \`CERT_DIR/gmailkey.pem')\n" >> /etc/mail/sendmail.mc
    fi
    
    if [ ! -f /etc/mail/auth/client-info ];then
        mkdir -p mkdir /etc/mail/auth
        echo "AuthInfo:smtp.gmail.com \"U:${GMAIL_NAME}\" \"I:${GMAIL_USER}\" \"P:${GMAIL_PASS}\"\n" >> /etc/mail/auth/client-info
        cd /etc/mail/auth/
        makemap hash client-info < client-info
        chmod 700 /etc/mail/auth
        chmod 600 /etc/mail/auth/*
    fi
    
    if [ ! -d /etc/mail/certs ];then
        mkdir /etc/mail/certs
        cd /etc/mail/certs
        openssl dsaparam 1024 -out dsa1024 -out dsa1024.pem
        openssl req -x509 -nodes -days 3650 -newkey dsa:dsa1024.pem -out /etc/mail/certs/gmailcert.pem -keyout /etc/mail/certs/gmailkey.pem
        ln -s /etc/mail/certs/gmailcert.pem /etc/mail/certs/CAcert.pem
        openssl req -x509 -new -days 3650 -key /etc/mail/certs/gmailkey.pem -out /etc/mail/certs/gmailcert.pem
        chmod 700 /etc/mail/certs
        chmod 600 /etc/mail/certs/*
        cd /etc/mail
        make
    fi
    
    /etc/init.d/sendmail reload

fi