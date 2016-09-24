#!/bin/sh

set -e

### The virtualbox-ose-additions take a lot of space and seems to be no benefit
### in having it installed untill one uses X11 (shared folders do not work at
### all, and GUI integration requires X11). We leave the installation of GAs
### to the user.
##
## # https://www.freebsd.org/cgi/man.cgi?query=pkg&apropos=0&sektion=8
## if TMPDIR=/dev/null ASSUME_ALWAYS_YES=yes \
##   PACKAGESITE=file:///nonexistent \
##   pkg info -x 'pkg(-devel)?$' >/dev/null 2>&1; then
##   PKG_INSTALL="pkg install -y"
## else
##   PKG_INSTALL="pkg_add -r"
## fi
##
## sudo -i $PKG_INSTALL virtualbox-ose-additions
## sudo sh -c 'echo "vboxguest_enable=YES" >> /etc/rc.conf'
## sudo sh -c 'echo "vboxservice_enable=YES" >> /etc/rc.conf'
