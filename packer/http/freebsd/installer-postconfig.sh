#!/bin/sh

set -e

# Mount /dev filesystem if not mounted yet
test -e /dev/null || mount -t devfs none /dev

# Prepare interface and enable ssh
echo "ifconfig_em0=SYNCDHCP" >> /etc/rc.conf
echo "sshd_enable=YES" >> /etc/rc.conf

if [ ! -z "$HOSTNAME" ] ; then
  echo "hostname=\"$HOSTNAME\"" >> /etc/rc.conf;
elif [ ! -z `hostname` ]; then
  echo "hostname=\"`hostname`\"" >> /etc/rc.conf;
fi

# Add "vagrant" user
pw groupadd vagrant
echo "vagrant" | pw useradd vagrant -c "Vagrant User" -m -g vagrant -G wheel -s csh -h 0

# Stop/start networking
if [ `sysctl -n kern.osreldate` -eq '1200052' ] ; then
  # https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=223327
  echo "Applying workaround for #223327..."
  sysctl kern.chroot_allow_open_directories=2
fi

service netif restart

OSRELDATE=`sysctl -n kern.osreldate`
OSRELEASE=`sysctl -n kern.osrelease`
osrelease=`sysctl -n kern.osrelease|tr '[:upper:]' '[:lower:]'`
ARCH=`sysctl -n hw.machine_arch`

echo "OSRELDATE: $OSRELDATE"
echo "OSRELEASE: $OSRELEASE"
echo "osrelease: $osrelease"

# Install sudo
if [ "$OSRELDATE" -ge '902000' ]; then
  echo "Using pkgng tools..."
  pkg -N 2>&1 > /dev/null || ASSUME_ALWAYS_YES=yes pkg bootstrap -f
  if [ ! -e /usr/local/etc/pkg/repos ] &&  [ ! -e /etc/pkg ]; then
    mkdir -p /usr/local/etc/pkg/repos
    cat > /usr/local/etc/pkg/repos/FreeBSD.conf <<'!'
FreeBSD: {
  url: "pkg+http://pkg.FreeBSD.org/${ABI}/latest",
  mirror_type: "srv",
  signature_type: "none",
  fingerprints: "/usr/share/keys/pkg",
  enabled: yes
}
!
  fi
  pkg update
  pkg install -y ca_root_nss
  pkg install -y sudo
else
  echo "Using old pkg tools..."
  export PACKAGESITE="ftp://ftp-archive.freebsd.org/pub/FreeBSD-Archive/ports/${ARCH}/packages-${osrelease}/Latest/"
  if [ ! -z "$PACKAGESITE" ]; then
    echo "export PACKAGESITE=$PACKAGESITE" | tee -a /etc/profile
    echo "setenv PACKAGESITE $PACKAGESITE" >> /etc/csh.cshrc
    mkdir -p /usr/local/etc/sudoers.d && \
      echo "Defaults env_keep += \"PACKAGESITE\"" >> /usr/local/etc/sudoers.d/packagesite && \
      chmod 440 /usr/local/etc/sudoers.d/packagesite
  fi
  pkg_add -r sudo
  test -e /etc/ssl/cert.pem || ln -s /usr/local/share/certs/ca-root-nss.crt /etc/ssl/cert.pem
fi

# Add vagrant to sudoers (passwordless)
sh -c 'echo "vagrant ALL=(ALL) NOPASSWD: ALL" | (EDITOR="tee -a" /usr/local/sbin/visudo)'

# Set shorter autoboot delay
echo 'autoboot_delay=2' >> /boot/loader.conf
