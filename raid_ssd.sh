#!/bin/bash

# --------
# array of members
disks=(/dev/sdc /dev/sdd)
# RAID level
level="mirror"
# name of the RAID device
raid_dev="/dev/md2"
# --------
# little bit of bash array magic
# append "1" to the end of each element without looping
partitions=(${disks[@]/%/1})

# a variable storing the number of disks
n_disks=${#disks[*]}
echo "Number of disks: $n_disks"

for disk in ${disks[@]}
do
	if lshw -quiet -c disk | grep -q $disk
	then
		echo "Partitioning disk: $disk"
		fdisk -l $disk
		echo "n
		p
		1
		
		
		t
		83
		w" | fdisk $disk
		fdisk -l $disk
	else
		echo "Could not find $disk - exiting"
		exit 3
	fi
done

echo "Setting up the RAID array"
echo "y" | mdadm --create --verbose ${raid_dev} --level=$level --raid-devices=$n_disks ${partitions[*]}
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
pvcreate ${raid_dev}p1
vgcreate instancesvg ${raid_dev}p1
lvcreate -l 100%FREE -n instanceslv instancesvg
mkfs.ext4 /dev/instancesvg/instanceslv
lvdisplay

echo "Mounting filesystem permanently"
# backup fstab
cp /etc/fstab{,.`date +%Y%m%d-%H%M`.bak}
# add entry to fstab
echo "/dev/mapper/instancesvg-instanceslv /var/lib/nova/instances     ext4    defaults        0       0" >> /etc/fstab
mkdir -p /var/lib/nova/instances
mount /var/lib/nova/instances
chown -R nova:nova /var/lib/nova/instances
ls -la /var/lib/nova/instances

cat /proc/mdstat
