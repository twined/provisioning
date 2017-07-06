
#!/bin/bash

####################################
#   Setup
####################################

user="twined"
tmpfile="/.twined/runonce"
config_dir="/root/provisioning-digitalocean"

if [ -e ${tmpfile} ]; then
  echo "Provisioning already completed. Remove ${tmpfile} to run it again."
  exit 0
fi

# modules hack
# wget http://ftp.de.debian.org/debian/pool/main/l/linux/linux-image-3.16.0-4-amd64_3.16.7-ckt25-2_amd64.deb
# apk add dpkg
# apk add tar
# dpkg-deb -x linux-image-3.16.0-4-amd64_3.16.7-ckt25-2_amd64.deb /tmp/out/
# mv /tmp/out/lib/modules/ /lib/
# depmod -a
# rm linux-image-3.16.0-4-amd64_3.16.7-ckt25-2_amd64.deb
# rm /tmp/out/ -fr

# Add repos
echo "@edge http://nl.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories
echo "@edge http://nl.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories
echo "@edge http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories

# Upgrade Alpine and base packages
apk --update upgrade

# grsec
# apk add linux-grsec

# Extra stuff
apk add shadow@edge util-linux fail2ban bash htop wget curl git sudo nano supervisor nginx postgresql postgresql-contrib postgresql-client zsh openssl py2-pip
apk add imagemagick pngquant@edge libjpeg-turbo-utils gifsicle@edge

mkdir /etc/nginx/sites-available
mkdir /etc/nginx/sites-enabled

addgroup nginx www-data

cp ${config_dir}/networking/networking /etc/init.d/networking
cp ${config_dir}/nginx/nginx.conf /etc/nginx/nginx.conf
cp ${config_dir}/nginx/default /etc/nginx/sites-enabled/default
cp ${config_dir}/nginx/proxy_params /etc/nginx/proxy_params
cp ${config_dir}/sshd/sshd_config /etc/ssh/sshd_config
cp ${config_dir}/fail2ban/alpine-ssh.conf /etc/fail2ban/jail.d/alpine-ssh.conf

chmod +x /etc/init.d/networking

rc-update add nginx
rc-update add fail2ban

/etc/init.d/nginx restart
/etc/init.d/sshd restart
/etc/init.d/fail2ban restart

# postgres
mkdir /var/lib/postgresql
chown postgres /var/lib/postgresql
sudo -u postgres initdb -D /var/lib/postgresql/9.6/data
rc-update add postgresql

cp ${config_dir}/postgres/postgresql.conf /var/lib/postgresql/9.6/data/postgresql.conf
chown postgres /var/lib/postgresql/9.6/data/postgresql.conf
/etc/init.d/postgresql start

# supervisor
mkdir -p /etc/supervisor/conf.d
cp ${config_dir}/supervisor/supervisord.conf /etc/supervisord.conf
rc-update add supervisord
/etc/init.d/supervisord start

# add user
adduser ${user}
usermod -s /bin/zsh ${user}
usermod -aG wheel ${user}
usermod -aG www-data ${user}
cp ${config_dir}/zsh/zshrc /home/${user}/.zshrc
chown ${user}:${user} /home/${user}/.zshrc
echo "${user}    ALL=(ALL) ALL" >> /etc/sudoers

# iptables
rc-update add iptables
/etc/init.d/iptables save
cp ${config_dir}/iptables/v4 /etc/iptables/rules-save
iptables-restore < /etc/iptables/rules-save
/etc/init.d/iptables start

# copy ssh key

mkdir -p /home/twined/.ssh
cp /root/.ssh/authorized_keys /home/twined/.ssh
chown -R twined:twined /home/twined/.ssh
chmod 700 /home/twined/.ssh
chmod 600 /home/twined/.ssh/authorized_keys

# run alpine setup
# setup-alpine

# install backblaze client
pip install b2

# mark as provisioned
mkdir -p /.twined
touch ${tmpfile}

echo "done. did not run setup-alpine"
