#!/bin/bash

#Not tested script#

# lvm2 must be installed
dpkg -l lvm2 | grep '^ii'
if [ $? -eq 0 ]; then
    exit 1
fi

# Ceph needs a disk without a FSTYPE
lsblk --noheadings --output NAME,FSTYPE,MOUNTPOINT | awk '$2 == "" && $3 == "" { count++ } END { if (count > 0) print count }'