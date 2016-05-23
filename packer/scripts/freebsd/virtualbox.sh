#!/bin/sh

set -e

if [ `sysctl -n kern.osreldate` -ge '903000' ]; then
  sudo -i pkg install -y virtualbox-ose-additions
else
  sudo -i pkg_add -r virtualbox-ose-additions
fi

sudo sh -c 'echo "vboxguest_enable=YES" >> /etc/rc.conf'
sudo sh -c 'echo "vboxservice_enable=YES" >> /etc/rc.conf'
sudo sh -c 'echo "vagrant" | pw usermod root -h 0'
