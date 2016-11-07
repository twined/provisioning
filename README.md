# Server provisioning scripts

*In linode manager:*

  1. Create 3 new disks.
    a) boot - 256mb
    b) swap - 512mb
    c) root - remaining
  2. Create a config profile using the new disk images, (sda=boot, sdb=root, sdc=swap) GRUB2 and no Filesystem/Boot helpers
  3. Boot into rescue mode with the new disk images (sda=boot, sdb=root, sdc=swap).
  4. update-ca-certificates && wget https://raw.githubusercontent.com/twined/provisioning/master/alpine/bootstrap.sh && chmod +x bootstrap.sh && ./bootstrap.sh

*In alpine as root:*

    $ apk update && apk add ca-certificates wget && update-ca-certificates
    $ cd ~ && wget https://github.com/twined/provisioning/archive/master.tar.gz && tar xvf master.tar.gz
    $ cd ~/provisioning-master/alpine && chmod +x provision.sh && ./provision.sh
    $ su twined
    $ mkdir -p ~/.ssh
    $ nano authorized_keys

    Paste in your local machine's ~/.ssh/id_rsa.pub. Make sure there are no newlines

    $ chmod 600 authorized_keys
