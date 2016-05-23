#!/bin/sh

set -e

test -e ~/.ssh || mkdir ~/.ssh
fetch -o ~/.ssh/authorized_keys https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub
chmod 0700 ~/.ssh
chmod 0600 ~/.ssh/authorized_keys
