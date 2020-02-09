#!/bin/bash
sudo /sbin/mdadm --zero-superblock --force /dev/sd{b,c,d,e,f}
sudo /sbin/mdadm --create --verbose /dev/md0 -l 5 -n 5 /dev/sd{b,c,d,e,f}
sudo mkdir /etc/mdadm/
sudo echo "DEVICE partitions" > sudo /etc/mdadm/mdadm.conf
sudo /sbin/mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> sudo /etc/mdadm/mdadm.conf
sudo parted -s /dev/md0 mklabel gpt
sudo parted /dev/md0 mkpart primary ext4 0% 20%
sudo parted /dev/md0 mkpart primary ext4 20% 40%
sudo parted /dev/md0 mkpart primary ext4 40% 60%
sudo parted /dev/md0 mkpart primary ext4 60% 80%
sudo parted /dev/md0 mkpart primary ext4 80% 100%
for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md0p$i; done
sudo mkdir -p /raid/part{1,2,3,4,5}
for i in $(seq 1 5); do sudo mount /dev/md0p$i /raid/part$i; done
