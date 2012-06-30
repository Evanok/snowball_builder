#!/bin/sh

BASE_PATH=`pwd`
KERNEL=$PWD/kernel
JOBS=4
BIN_ARM=$BASE_PATH/arm-none-linux-gnueabi/bin/arm-none-linux-gnueabi-
ARCH=arm
CROSS_DIR=$BASE_PATH/arm-none-linux-gnueabi

CROSS_PARAMS="ARCH=$ARCH CROSS_COMPILE=$BIN_ARM"

error()
{
    echo "Error : $1"
    exit 1;
}

print_usage()
{
    echo
    echo "Usage: ${0##*/} [OPTION]... <project_name>"
    echo "shell program to build snowball system"
    echo
    cat <<EOF
      -h,--help                      display this help and exit
      -c,--config <file>             specify which config file to use (MANDATORY)
      -p,--project <project name>    provide a project (MANDATORY)
EOF
    echo
}


options=$(getopt -o hc:p -l help,config:,project: -- "$@")
if [ $? -ne  0 ]; then
    print_usage
    exit 1
fi


eval set -- "$options"

while true; do
    case "$1" in
        -h|--help)              print_usage && exit 0;;
        -c|--config)            CONFIG=$2; shift 2;;
        -p|--project)           PROJECT=$2; shift 2;;
        --)                     shift 1; break;;
        *)                      break;;
    esac
done



if [ ! -z "$CONFIG" ]; then
    if [ ! -f $CONFIG ]; then
        error "Configure file: $CONFIG not found."
    fi;
else
    error "You must provide a valid configure file."
fi;

if [ -z "$PROJECT" ]; then
    error "You must provide a valid project name."
fi;

if [ ! -d $BASE_PATH/system ]; then
    mkdir $BASE_PATH/system
fi;

sudo rm -rf $BASE_PATH/system/$PROJECT
mkdir $BASE_PATH/system/$PROJECT

ROOTFS=$BASE_PATH/system/$PROJECT/rootfs_config

 # COMPILE KERNEL SOURCE

echo -n "Check kernel dir..."
if [ ! -d $KERNEL ]; then
   git clone https://github.com/Evanok/igloo_kernel_android_linux3.3.git $KERNEL >/dev/null
fi
echo " Done."

echo -n "Check cross arm dir..."
if [ ! -d $CROSS_DIR ]; then
   git clone /home/arthur/git/arm-none-linux-gnueabi.git $CROSS_DIR >/dev/null
fi
echo " Done."

echo "Compiling kernel [jobs = $JOBS]";

MOD_PATH="INSTALL_MOD_PATH=$ROOTFS/modules/ "

echo ${BASE_PATH}
echo "Cleaning kernel source...."
cd $KERNEL && make $CROSS_PARAMS clean
cd $KERNEL && make $CROSS_PARAMS distclean
echo "Done."

echo "cp $BASE_PATH/$CONFIG $KERNEL/.config"
cp $BASE_PATH/$CONFIG $KERNEL/.config
echo "Bulding uImage..."
echo "cd $KERNEL && make $CROSS_PARAMS -j $JOBS uImage"
cd $KERNEL && make $CROSS_PARAMS -j $JOBS uImage
res=`echo $?`
if [ $res -ne 0 ]; then
    echo "Error during make uImage ($res)".
    exit $res
fi;
echo "Done."

echo "Installing modules"
cd $KERNEL && make $CROSS_PARAMS $MOD_PATH -j$JOBS modules
cd $KERNEL && make $CROSS_PARAMS $MOD_PATH -j$JOBS modules_install
echo "Done."

cd $BASE_PATH

mkdir $BASE_PATH/system/$PROJECT/configs

# END COMPILE

# CREATE ROOT FILESYSTEM

mkdir $ROOTFS/scripts
mkdir $ROOTFS/config
mkdir $ROOTFS/boot

$BASE_PATH/config_creator $ROOTFS

echo "Creating filesystem";

if [ ! -d $ROOTFS ]; then
    error "emdebian sources not found";
fi

cd $ROOTFS

echo -n "Multistrap...."
sudo multistrap -f $ROOTFS/config/snowball_multistrap_configuration
rm -rf modules/lib
echo " Done...."

cp $BASE_PATH/$CONFIG $BASE_PATH/system/$PROJECT/configs/
cp $KERNEL/arch/$ARCH/boot/uImage $BASE_PATH/system/$PROJECT/rootfs_config/boot/uImage

cd $BASE_PATH

# END ROOTFS
