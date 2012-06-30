#!/bin/sh


DEV_ENTRY=/dev/sdb
PROJECT=android-linux3.3
HERE=`pwd`

date

echo -n "Copying uImage..."
mkdir $HERE/sd_boot
sudo mount ${DEV_ENTRY}1 $HERE/sd_boot
sudo cp $HERE/system/$PROJECT/rootfs_config/boot/uImage $HERE/sd_boot/.
sync
sudo umount ${DEV_ENTRY}1
rm -rf $HERE/sd_boot
echo " Done."
echo

echo -n "Copying rootfs..."
mkdir $HERE/sd_rootfs
sudo mount ${DEV_ENTRY}2 $HERE/sd_rootfs
sudo cp $HERE/system/$PROJECT/rootfs_config/boot/rootfs--snowball.tar $HERE/sd_rootfs/.
cd $HERE/sd_rootfs && sudo tar -xf rootfs--snowball.tar
sudo rm $HERE/sd_rootfs/rootfs--snowball.tar
sudo cp -R $HERE/firmware/* $HERE/sd_rootfs/lib/firmware/.
sync
sudo umount ${DEV_ENTRY}2
rm -rf $HERE/sd_rootfs
echo " Done."
