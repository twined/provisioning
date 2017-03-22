# Server provisioning scripts

*For digital ocean*

Follow instructions from https://github.com/eskin/digitalocean-alpine

*In alpine as root:*

    $ apk update && apk add ca-certificates wget && update-ca-certificates
    $ cd ~ && wget -N https://github.com/twined/provisioning/archive/digitalocean.tar.gz && tar xvf digitalocean.tar.gz
    $ cd ~/provisioning-digitalocean/alpine && chmod +x provision.sh && ./provision.sh

Now exit the shell, and try to ssh from your local machine

    $ ssh -p 30000 twined@<ip>
