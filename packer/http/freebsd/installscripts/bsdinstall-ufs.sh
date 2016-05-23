PARTITIONS="ada0"
DISTRIBUTIONS="kernel.txz base.txz"

if [ ! -z "$INSTALL_PORTS" ]; then
  case "$INSTALL_PORTS" in
    1|TRUE|YES)
      DISTRIBUTIONS="$DISTRIBUTIONS ports.txz"
      ;;
  esac
fi

#!/bin/sh

set -e

# Prepare interface and enable ssh
echo "ifconfig_em0=DHCP" >> /etc/rc.conf
echo "sshd_enable=YES" >> /etc/rc.conf

# Add "vagrant" user
pw groupadd vagrant
echo "vagrant" | pw useradd vagrant -c "Vagrant User" -m -g vagrant -G wheel -s csh -h 0

# Start networking
dhclient "em0"

OSRELDATE=`sysctl -n kern.osreldate`
ARCH=`sysctl -n hw.machine_arch`

echo "OSRELDATE: $OSRELDATE"

# Install sudo
if [ "$OSRELDATE" -ge '903000' ]; then
  echo "Using pkgng tools..."
  pkg -N 2>&1 > /dev/null || ASSUME_ALWAYS_YES=yes pkg bootstrap -f
  pkg install -y ca_root_nss
  pkg install -y sudo
else
  echo "Using old pkg tools..."
  case "$OSRELDATE" in
    902*)
      export PACKAGESITE="ftp://ftp-archive.freebsd.org/pub/FreeBSD-Archive/ports/${ARCH}/packages-9.2-release/Latest/"
      ;;
    *)
      true
      ;;
  esac
  if [ ! -z "$PACKAGESITE" ]; then
    echo "PACKAGESITE=$PACKAGESITE" | tee -a /etc/profile
    echo "setenv PACKAGESITE $PACKAGESITE" >> /etc/csh.cshrc
  fi
  pkg_add -r sudo
fi

# Add vagrant to sudoers (passwordless)
sh -c 'echo "vagrant ALL=(ALL) NOPASSWD: ALL" | (EDITOR="tee -a" /usr/local/sbin/visudo)'

# Set shorter autoboot delay
echo 'autoboot_delay=2' >> /boot/loader.conf

# Start SSH and wait for the box to be provisioned
echo "Installed successfully, starting sshd server..."
service sshd start
echo '*****************************************************************'
echo '***                                                           ***'
echo '***                                                           ***'
echo '***                                                           ***'
echo '*** Please do NOT reboot/poweroff, provisioning in progres... ***'
echo '***                                                           ***'
echo '***                                                           ***'
echo '***                                                           ***'
echo '*****************************************************************'
