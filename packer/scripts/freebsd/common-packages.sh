#!/bin/sh

set -e

if [ `sysctl -n kern.osreldate` -ge '903000' ]; then
  PKG_INSTALL="pkg install -y"
else
  PKG_INSTALL="pkg_add -r"
fi

sudo -i $PKG_INSTALL rsync
sudo -i $PKG_INSTALL curl
