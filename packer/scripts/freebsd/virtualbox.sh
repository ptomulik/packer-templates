#!/bin/sh

set -e

### The virtualbox-ose-additions take a lot of space and seems to be no benefit
### in having it installed untill one uses X11 (shared folders do not work at
### all, and GUI integration requires X11). We leave the installation of GAs
### to the user.
##
## if [ `sysctl -n kern.osreldate` -ge '903000' ]; then
##   PKG_INSTALL="pkg install -y"
## else
##   PKG_INSTALL="pkg_add -r"
## fi
##
## sudo -i $PKG_INSTALL virtualbox-ose-additions
## sudo sh -c 'echo "vboxguest_enable=YES" >> /etc/rc.conf'
## sudo sh -c 'echo "vboxservice_enable=YES" >> /etc/rc.conf'

sudo sh -c 'echo "vagrant" | pw usermod root -h 0'
