#!/bin/sh

set -e

OSRELDATE=`sysctl -n kern.osreldate`

if [ "$OSRELDATE" -ge '903000' ]; then
  sudo -i pkg install -y port-maintenance-tools
  if [ "$OSRELDATE" -le '903999' ]; then
    sudo -i 'echo "WITH_PKGNG=yes" >> /etc/make.conf'
  fi
else
  sudo -i pkg_add -r port-maintenance-tools
fi
