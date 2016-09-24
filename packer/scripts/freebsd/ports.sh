#!/bin/sh

set -e

OSRELDATE=`sysctl -n kern.osreldate`

# https://www.freebsd.org/cgi/man.cgi?query=pkg&apropos=0&sektion=8
if TMPDIR=/dev/null ASSUME_ALWAYS_YES=yes \
  PACKAGESITE=file:///nonexistent \
  pkg info -x 'pkg(-devel)?$' >/dev/null 2>&1; then

  if [ "$OSRELDATE" -le '903999' ]; then
    echo 'WITH_PKGNG=yes' | sudo tee -a '/etc/make.conf'
  fi
  PKG_INSTALL="pkg install -y"

else

  PKG_INSTALL="pkg_add -r"

fi

sudo -i $PKG_INSTALL port-maintenance-tools
if [ ! -e /tmp/skip-portsnap ]; then
  sudo -i script -t 0 -q /dev/stdout portsnap fetch
  sudo -i portsnap extract > /dev/null
fi

# On some installation ports are not ready yet and require to run "make index"
if make search -C /usr/ports path='misc/figlet$' | \
   grep 'Please run make index' > /dev/null 2>&1; then
  echo 'Running "make index -C /usr/ports"...'
  sudo make index -C /usr/ports
fi

# Fix for hanging "script -qa ... " in pkgtools.rb used by portupgrade
if [ -d '/usr/local/lib/ruby' ]; then
  echo "/usr/local/lib/ruby is a directory";
  for F in `find /usr/local/lib/ruby -name 'pkgtools.rb' -type f`; do
    UNCHMOD=false;
    echo "patching $F...";
    sudo test -w $F || (sudo chmod u+w $F; UNCHMOD=true);
    sudo sed -e "s/\[script_path(), '-qa', file, \*args\]/[script_path(), '-t', '0', '-qa', file, \*args]/" \
             -e "s/\['\/usr\/bin\/script', '-qa', file, \*args\]/['\/usr\/bin\/script', '-t', '0', '-qa', file, \*args]/" \
             -i '' $F;
    if $UNCHMOD; then sudo chmod u-w $F; fi
  done
fi

# Add ftp-archive as backup site for older FreeBSD versions
if [ "$OSRELDATE" -lt '903000' ]; then
    export MASTER_SITE_BACKUP='ftp://ftp-archive.freebsd.org/pub/FreeBSD-Archive/ports/distfiles/'
    echo "export MASTER_SITE_BACKUP=$MASTER_SITE_BACKUP" | sudo tee -a /etc/profile
    echo "setenv MASTER_SITE_BACKUP $MASTER_SITE_BACKUP" | sudo tee -a /etc/csh.cshrc
    (test -e /usr/local/etc/sudoers.d || sudo mkdir -p /usr/local/etc/sudoers.d) && \
      echo "Defaults env_keep += \"MASTER_SITE_BACKUP\"" | sudo tee -a /usr/local/etc/sudoers.d/mastersite && \
      sudo chmod 440 /usr/local/etc/sudoers.d/mastersite
fi
