#!/bin/sh

set -e

OSRELDATE=`sysctl -n kern.osreldate`
OSRELEASE=`sysctl -n kern.osrelease`
OSVERSION=`echo $OSRELEASE | cut -d . -f 1`

fetch -o /tmp/installer-postconfig.sh "http://$HTTPIP:$HTTPPORT/freebsd/installer-postconfig.sh";

if [ -e /usr/libexec/bsdinstall/script ]; then

 fetch -o /tmp/bsdinstall.sh "http://$HTTPIP:$HTTPPORT/freebsd/bsdinstall.sh"
 sed -e '/^#!\s*\/bin\/sh/ {' -e 'r /tmp/installer-postconfig.sh' -e 'd' -e'}' -i '' /tmp/bsdinstall.sh
 ifconfig em0 down
 hostname "freebsd-$OSVERSION"
 bsdinstall script /tmp/bsdinstall.sh

else

  # Some FreeBSD version may have no "bsdinstall script", so we try to use pc-sysinstall
  fetch -o /tmp/pc-sysinstall.conf.in "http://$HTTPIP:$HTTPPORT/freebsd/pc-sysinstall.conf.in"

  DISTFILES="base kernel"

  case $INSTALL_PORTS in
    yes|YES|1)
      if [ $OSRELDATE -lt 902000 ]; then
        # On ancient FreeBSD versions we install ports from distribution (CD)
        # and don't update them. Newer ports (fetched by portsnap) are
        # incompatible with locally installed make.
        DISTFILES="$DISTFILES ports";
        echo "runCommand=touch /tmp/skip-portsnap" >> /tmp/pc-sysinstall.conf.in
      fi
      ;;
    *)
      ;;
  esac

  sed -e "s/@hostname@/freebsd-$OSVERSION/" \
      -e "s/@distFiles@/$DISTFILES/" \
      /tmp/pc-sysinstall.conf.in > /tmp/pc-sysinstall.conf

  gmirror load

  if [ $OSRELDATE -lt 1000000 ]; then
    # pc-sysinstall provided by FreeBSD < 10.0 is kinda useless, as it does not
    # support dists (*.txz files provided on installation CD, DVD ...), so we
    # download a version from 10.1 and use it
    fetch -o /tmp/pc-sysinstall.tar.gz "http://$HTTPIP:$HTTPPORT/freebsd/pc-sysinstall.tar.gz"
    (cd /tmp && tar -zxf pc-sysinstall.tar.gz)
    export PROGDIR=/tmp/pc-sysinstall
    PCSYSINSTALL="/tmp/pc-sysinstall/pc-sysinstall"
  else
    PCSYSINSTALL="pc-sysinstall"
  fi
  ifconfig em0 down
  $PCSYSINSTALL -c /tmp/pc-sysinstall.conf

  FSMNT=`cat /tmp/fsmnt`
  mount /dev/ada0s1a $FSMNT
  test -e $FSMNT/dev/null || mount -t devfs none $FSMNT/dev
  chroot $FSMNT service sshd start

  echo '*****************************************************************'
  echo '***                                                           ***'
  echo '***                                                           ***'
  echo '***                                                           ***'
  echo '*** Please do NOT reboot/poweroff, provisioning in progres... ***'
  echo '***                                                           ***'
  echo '***                                                           ***'
  echo '***                                                           ***'
  echo '*****************************************************************'
fi
