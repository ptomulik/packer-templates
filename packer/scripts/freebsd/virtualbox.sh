#!/bin/sh

set -e

if [ `sysctl -n kern.osreldate` -ge '903000' ]; then
  PKG_INSTALL="pkg install -y"
else
  PKG_INSTALL="pkg_add -r"
fi

sudo -i $PKG_INSTALL virtualbox-ose-additions

sudo sh -c 'echo "vboxguest_enable=YES" >> /etc/rc.conf'
sudo sh -c 'echo "vboxservice_enable=YES" >> /etc/rc.conf'
sudo sh -c 'echo "vagrant" | pw usermod root -h 0'
