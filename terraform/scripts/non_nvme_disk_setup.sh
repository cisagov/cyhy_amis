#!/usr/bin/env bash

# Input variables are:
# num_disks - the number of extra (non-root) disks that are expected
# to be attached
# device_name - the device name for the disk of interest (/dev/xvdb,
# for example)
# mount_point - the directory where the disk is to be mounted
# label - the label to give the disk if it is necessary to create a
# file system
# fs_type - the file system type to use if it is necessary to create a
# file system
# mount_options - a comma-separated list of options to pass when
# mounting (defaults or defaults,noauto, for example)

set -o nounset
set -o errexit
set -o pipefail

while [ `lsblk | grep -c " disk"` -lt ${num_disks} ]
do
    echo Waiting for disks to attach...
    sleep 5
done

# Create a file system on the EBS volume if one was not already there.
blkid -c /dev/null ${device_name} || mkfs -t ${fs_type} -L ${label} ${device_name}

# Grab the UUID of this volume
uuid=$(blkid -s UUID -o value ${device_name})

# Mount the file system
mount UUID="$uuid" -o ${mount_options} ${mount_point}

# Save the mount point in fstab, so the file system is remounted if
# the instance is rebooted
echo "# ${label}" >> /etc/fstab
echo "UUID=$uuid ${mount_point} ${fs_type} ${mount_options} 0 2" >> /etc/fstab
