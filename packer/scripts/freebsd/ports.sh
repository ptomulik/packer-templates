#!/bin/sh

set -e

OSRELDATE=`sysctl -n kern.osreldate`

if [ "$OSRELDATE" -ge '903000' ]; then
  if [ "$OSRELDATE" -le '903999' ]; then
    echo 'WITH_PKGNG=yes' | sudo tee -a '/etc/make.conf'
  fi
  PKG_INSTALL="pkg install -y"
else
  PKG_INSTALL="pkg_add -r"
fi
sudo -i $PKG_INSTALL port-maintenance-tools
sudo -i script -q /dev/null portsnap fetch
sudo -i portsnap extract > /dev/null
