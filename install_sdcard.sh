#!/bin/sh

# AUTHORS : ARTHUR LAMBERT
# DATE : 16/07/2012
# DESCRIPTION : DEPLOY SYSTEM ON SNOWBALL

# reset error log

echo >/tmp/log_error_snowball

###############################################################################
# print usage for this script
print_usage()
{
    echo
    echo "Usage: ${0##*/} [OPTION]... <project_name> <dev entry>"
    echo "shell script to deploye snowball system with rootfs and kernel on sd micro card"
    echo
    cat <<EOF
      -h,--help                   display this help and exit
      -d,--dev <file>             specify on which /dev entry is plug your sd card(MANDATORY)
      -p,--project <project name> provide a project name (MANDATORY)
EOF
    echo
}
###############################################################################

###############################################################################
# print error message and return error code 1 when $? is different than 0
check_error()
{
    if [ $2 -ne 0 ]; then
	echo; echo;
	echo "############################################################"
	cat /tmp/log_error_snowball
	echo "############################################################"
	echo
	echo "Error (code : $2) : $1"
	rm -rf $HERE/sd_rootfs
	rm -rf $HERE/sd_boot
	exit $2;
    fi
}
###############################################################################

# Handle arguments through getopt command

options=$(getopt -o hd:p: -l help,dev:,project: -- "$@")
if [ $? -ne  0 ] || [ $# -ne 4 ]; then
    print_usage
    exit 1
fi


eval set -- "$options"

while true; do
    case "$1" in
        -h|--help)              echo lol; print_usage && exit 0;;
        -d|--dev)               DEV_ENTRY=$2; shift 2;;
        -p|--project)           PROJECT=$2; shift 2;;
	*)                      break;;
    esac
done


HERE=`pwd`

date

echo "DEV=$DEV_ENTRY, PROJECT=$PROJECT"
echo

if [ -z $PROJECT ] || [ ! -d $HERE/output/$PROJECT ]; then
    check_error "Incorrect $PROJECT value. $HERE/output/$PROJECT directory does not exist." 42
fi;


if [ -z $DEV_ENTRY ] || [ ! -e /dev/$DEV_ENTRY ]; then
    check_error "Bad dev entry : $DEV_ENTRY, /dev/$DEV_ENTRY does not exist." 42
fi;

sudo umount /dev/${DEV_ENTRY}1 2>>/tmp/log_error_snowball
sudo umount /dev/${DEV_ENTRY}2 2>>/tmp/log_error_snowball

echo -n "Copying uImage..."
mkdir $HERE/sd_boot 2>>/tmp/log_error_snowball
sudo mount /dev/${DEV_ENTRY}1 $HERE/sd_boot 2>>/tmp/log_error_snowball
sudo rm -rf $HERE/sd_boot/* 2>>/tmp/log_error_snowball
check_error " Unable to mount ${DEV_ENTRY}1." $?
sudo cp $HERE/output/$PROJECT/uImage $HERE/sd_boot/. 2>>/tmp/log_error_snowball
sync
sudo umount $HERE/sd_boot 2>>/tmp/log_error_snowball
rm -rf $HERE/sd_boot
echo " Done."
echo

echo -n "Copying rootfs..."
mkdir $HERE/sd_rootfs 2>>/tmp/log_error_snowball
sudo mount /dev/${DEV_ENTRY}2 $HERE/sd_rootfs 2>>/tmp/log_error_snowball
check_error " Unable to mount ${DEV_ENTRY}2." $?
sudo rm -rf $HERE/sd_rootfs/* 2>>/tmp/log_error_snowball
sudo cp $HERE/output/$PROJECT/rootfs-armel-snowball.tar $HERE/sd_rootfs/. 2>>/tmp/log_error_snowball
cd $HERE/sd_rootfs && sudo tar -xf rootfs-armel-snowball.tar 2>>/tmp/log_error_snowball
cd $HERE
sudo rm $HERE/sd_rootfs/rootfs-armel-snowball.tar 2>>/tmp/log_error_snowball
sync
sleep 5
sudo umount $HERE/sd_rootfs 2>>/tmp/log_error_snowball
sudo rm -rf $HERE/sd_rootfs 2>>/tmp/log_error_snowball
echo " Done."

date
