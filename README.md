# Server provisioning scripts

*For digital ocean*

Follow instructions from https://github.com/eskin/digitalocean-alpine

*In alpine as root:*

    $ apk update && apk add ca-certificates wget && update-ca-certificates
    $ cd ~ && wget -N https://github.com/twined/provisioning/archive/master.tar.gz && tar xvf master.tar.gz
    $ cd ~/provisioning-master/alpine && chmod +x provision.sh && ./provision.sh
    $ su twined
    $ mkdir -p ~/.ssh && cd ~/.ssh && nano authorized_keys

    Paste in your local machine's ~/.ssh/id_rsa.pub. Make sure there are no newlines

    $ chmod 600 authorized_keys

Now exit the shell, and try to ssh from your local machine

    $ ssh -p 30000 twined@<ip>
