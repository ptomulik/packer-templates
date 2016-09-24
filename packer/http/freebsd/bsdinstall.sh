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
