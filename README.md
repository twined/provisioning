# Server provisioning scripts

*For digital ocean*

Follow instructions from https://github.com/eskin/digitalocean-alpine
Kernel: Debian 8.0 x64 vmlinuz-3.16.0-4-amd64 (3.16.7-ckt9-3~deb8u1)

*In alpine as root:*

    $ apk update && apk add ca-certificates wget && update-ca-certificates
    $ cd ~ && wget -N https://github.com/twined/provisioning/archive/digitalocean.tar.gz && tar xvf digitalocean.tar.gz
    $ cd ~/provisioning-digitalocean/alpine && chmod +x provision.sh && ./provision.sh

Now exit the shell, and try to ssh from your local machine

    $ ssh -p 30000 twined@<ip>

*App/database splits*

There are `provision-app.sh` and `provision-db.sh` scripts available as well.
