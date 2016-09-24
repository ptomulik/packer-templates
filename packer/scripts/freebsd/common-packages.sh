#!/bin/sh

set -e

# https://www.freebsd.org/cgi/man.cgi?query=pkg&apropos=0&sektion=8
if TMPDIR=/dev/null ASSUME_ALWAYS_YES=yes \
  PACKAGESITE=file:///nonexistent \
  pkg info -x 'pkg(-devel)?$' >/dev/null 2>&1; then
  PKG_INSTALL="pkg install -y"
else
  PKG_INSTALL="pkg_add -r"
fi

sudo -i $PKG_INSTALL rsync
sudo -i $PKG_INSTALL curl
