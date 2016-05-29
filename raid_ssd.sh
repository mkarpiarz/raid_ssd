#!/bin/bash

set -x

# --------
# array of members
disks=(/dev/sdc /dev/sdd)
# RAID level
level="mirror"
# name of the RAID device
raid_dev="/dev/md2"
# --------

# check if the user is root
if [ $EUID -ne 0 ]; then
	echo "This script should be run as root." > /dev/stderr
	exit 1
fi

# a variable storing the number of disks
n_disks=${#disks[*]}
echo "Number of disks: $n_disks"

for disk in ${disks[@]}
do
	echo "Partitioning disk: $disk"
	fdisk -l $disk
	echo "n
	p
	1
	
	
	t
	83
	w" | fdisk $disk
	fdisk -l $disk
done

# check if mdadm is installed
if [[ -z `dpkg --get-selections | grep -w ^mdadm | grep -w install$` ]]
then
	echo "ERROR: Please install mdadm. Exiting."
	exit 2
fi

echo "Setting up the RAID array"
echo "y" | mdadm --create --verbose ${raid_dev} --level=$level --raid-devices=$n_disks ${disks[*]}
mdadm --detail ${raid_dev}
cat /proc/mdstat

set -
