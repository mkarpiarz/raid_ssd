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

echo "Stop nova-compute (just in case)"
service nova-compute stop

echo "Setting up the RAID array"
echo "y" | mdadm --create --verbose ${raid_dev} --level=$level --raid-devices=$n_disks ${disks[*]}
mdadm --detail ${raid_dev}
cat /proc/mdstat

echo "Creating a partition on the array"
echo "n
p
1


t
8e
w" | fdisk ${raid_dev}

echo "Creating LVM"
# check if LVM is installed
if [[ -z `dpkg --get-selections | grep -w ^lvm2 | grep -w install$` ]]
then
	echo "ERROR: Please install lvm2. Exiting."
	exit 3
fi

pvcreate ${raid_dev}p1
vgcreate instancesvg ${raid_dev}p1
lvcreate -l 100%FREE -n instanceslv instancesvg
mkfs.ext4 /dev/instancesvg/instanceslv
lvdisplay

echo "Moving instances data"
mkdir -p /mnt/instances
mount /dev/instancesvg/instanceslv /mnt/instances/
rsync -av --progress /var/lib/nova/instances/* /mnt/instances/
mv /var/lib/nova/instances /var/lib/nova/instances.old
umount /mnt/instances

echo "Mounting filesystem permanently"
# backup fstab
cp /etc/fstab{,.`date +%Y%m%d-%H%M`.bak}
# add entry to fstab
echo "/dev/mapper/instancesvg-instanceslv /var/lib/nova/instances     ext4    defaults        0       0" >> /etc/fstab
mkdir /var/lib/nova/instances
mount /var/lib/nova/instances
chown -R nova:nova /var/lib/nova/instances
ls -la /var/lib/nova/instances

echo "Restarting nova-compute"
service nova-compute restart

cat /proc/mdstat

set -
