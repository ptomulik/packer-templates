#!/bin/bash -eux

# Apt cleanup
DEBIAN_FRONTEND=noninteractive apt-get autoremove -y -q
DEBIAN_FRONTEND=noninteractive apt-get update -y -q

# Delete unneeded files
rm -f /home/vagrant/*.sh

# Add `sync` so Packer doesn't quit too early, before large file is deleted
sync
