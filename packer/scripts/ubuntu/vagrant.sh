#!/bin/sh

set -e

test -e ~/.ssh || mkdir ~/.ssh
wget --no-check-certificate -O ~/.ssh/authorized_keys https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub
chown -R vagrant:vagrant ~/.ssh
chmod 0700 ~/.ssh
chmod 0600 ~/.ssh/authorized_keys
