
#!/bin/bash

####################################
#   Setup
####################################

user="twined"
tmpfile="/.twined/runonce"
config_dir="/root/provisioning-master"

if [ -e ${tmpfile} ]; then
  echo "Provisioning already completed. Remove ${tmpfile} to run it again."
  exit 0
fi

# Add repos
echo "@edge http://nl.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories
echo "@edge http://nl.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories
echo "@edge http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories

# Upgrade Alpine and base packages
apk --update upgrade

# Extra stuff

apk add shadow@edge util-linux fail2ban bash htop wget curl git sudo nano supervisor nginx postgresql postgresql-client zsh
apk add imagemagick pngquant@edge libjpeg-turbo-utils gifsicle@edge

mkdir /etc/nginx/sites-available
mkdir /etc/nginx/sites-enabled

addgroup nginx www-data

cp ${config_dir}/nginx/nginx.conf /etc/nginx/nginx.conf
cp ${config_dir}/nginx/default /etc/nginx/sites-enabled/default
cp ${config_dir}/nginx/proxy_params /etc/nginx/proxy_params
cp ${config_dir}/sshd/sshd_config /etc/ssh/sshd_config
cp ${config_dir}/fail2ban/alpine-ssh.conf /etc/fail2ban/jail.d/alpine-ssh.conf

rc-update add nginx
rc-update add fail2ban

/etc/init.d/nginx restart
/etc/init.d/sshd restart
/etc/init.d/fail2ban restart

# postgres
mkdir /var/lib/postgresql
chown postgres /var/lib/postgresql
sudo -u postgres initdb -D /var/lib/postgresql/9.5/data
rc-update add postgres

cp ${config_dir}/postgres/postgresql.conf /var/lib/postgresql/9.5/data/postgresql.conf
chown postgres /var/lib/postgresql/9.5/data/postgresql.conf
/etc/init.d/postgres start

# supervisor
mkdir -p /etc/supervisor/conf.d
cp ${config_dir}/supervisor/supervisord.conf /etc/supervisord.conf
rc-update add supervisord
/etc/init.d/supervisord start

# add user
adduser ${user}
usermod -s /bin/zsh ${user}
usermod -aG wheel ${user}
cp ${config_dir}/zsh/zshrc /home/${user}/.zshrc
echo "${user}    ALL=(ALL) ALL" >> /etc/sudoers

# iptables
rc-update add iptables
/etc/init.d/iptables save
cp &{config_dir}/iptables/v4 /etc/iptables/rules-save
iptables-restore < /etc/iptables/rules-save
/etc/init.d/iptables start

# run alpine setup
setup-alpine

# mark as provisioned
mkdir -p /.twined
touch ${tmpfile}
