#!/bin/sh

set -e

OSRELDATE=`sysctl -n kern.osreldate`

if [ "$OSRELDATE" -ge '903000' ]; then
  if [ "$OSRELDATE" -le '903999' ]; then
    sudo -i 'echo "WITH_PKGNG=yes" >> /etc/make.conf'
  fi
  PKG_INSTALL="pkg install -y"
else
  PKG_INSTALL="pkg_add -r"
fi
sudo -i $PKG_INSTALL port-maintenance-tools
