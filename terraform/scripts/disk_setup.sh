#!/usr/bin/env bash

# Input variables are:
# num_disks - the number of extra (non-root) disks that are expected
# to be attached
# device_name - the old-style device name for the disk of interest
# (/dev/xvdb, for example)
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

nvme_devices=$(find /dev | grep -i 'nvme[0-9][1-9]\?n1$')

# Find our device from among the NVMe devices by checking each one's
# vendor-specific region for the non-NVMe device name as it is
# specified in the Terraform code.  (AWS is nice enough to stash it
# there for us.)
#
# This is important because with multiple NVMe devices the order is
# non-deterministic.
for nvme_device in $nvme_devices
do
    # Turn off pipefail and errexit for this one command.  This
    # command will always fail if the NVMe disk isn't the one we're
    # looking for.
    set +o errexit; set +o pipefail
    non_nvme_device_name=$(nvme id-ctrl -v $nvme_device | grep -o ${device_name})
    set -o errexit; set -o pipefail

    if [ "$non_nvme_device_name" = "${device_name}" ]
    then
        # We've found our device

        # Create a file system on the EBS volume if one was not
        # already there.
        blkid -c /dev/null $nvme_device || mkfs -t ${fs_type} -L ${label} $nvme_device

        # Grab the UUID of this volume
        uuid=$(blkid -s UUID -o value $nvme_device)

        # Mount the file system
        mount UUID="$uuid" -o ${mount_options} ${mount_point}

        # Save the mount point in fstab, so the file system is
        # remounted if the instance is rebooted
        echo "# ${label}" >> /etc/fstab
        echo "UUID=$uuid ${mount_point} ${fs_type} ${mount_options} 0 2" >> /etc/fstab
    fi
done
