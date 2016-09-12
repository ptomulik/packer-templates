PARTITIONS=
for DEV in 'ada0' 'da0'; do
  test -e "/dev/$DEV" && PARTITIONS=$DEV && break;
done

if [ -z "$PARTITIONS" ]; then
  echo 'ERROR: could not determine the disk device to be partitioned' >&2
  exit 1
fi

DISTRIBUTIONS="kernel.txz base.txz"

#!/bin/sh

set -e

# Prepare interface and enable ssh
echo "ifconfig_em0=SYNCDHCP" >> /etc/rc.conf
echo "sshd_enable=YES" >> /etc/rc.conf

# Add "vagrant" user
pw groupadd vagrant
echo "vagrant" | pw useradd vagrant -c "Vagrant User" -m -g vagrant -G wheel -s csh -h 0

# Stop/start networking
service netif restart

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
    mkdir -p /usr/local/etc/sudoers.d && echo "Defaults env_keep += \"PACKAGESITE\"" >> /usr/local/etc/sudoers.d/packagesite
  fi
  pkg_add -r sudo
  test -e /etc/ssl/cert.pem || ln -s /usr/local/share/certs/ca-root-nss.crt /etc/ssl/cert.pem
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
