#!/usr/bin/zsh

#set -e

echo_blue() {
    local font_blue="\033[94m"
    local font_bold="\033[1m"
    local font_end="\033[0m"

    echo -e "\n${font_blue}${font_bold}${1}${font_end}"
}

echo_blue "[Building the base image]"

IMAGE=${IMAGE:-creepinson/timos}
podman build -t creepinson/timos -f ./Dockerfile.base .

# Export the image to a tar file
cid=$(podman run -d ${IMAGE})
podman export $cid > timos.tar

# Clean up the container
podman rm $cid

# Extract the tar file
mkdir build
tar -xvf timos.tar -C build
rm timos.tar

# Build the image

DRIVE=${1:-/dev/sda1}
## replace __ROOT__ with the root device

echo_blue "[Create disk image]"
dd if=/dev/zero of=./timos.img bs=$(expr 1024 \* 1024 \* 1024 \* 2) count=1

echo_blue "[Make partition]"
sfdisk ./timos.img < ./partition.txt

echo_blue "\n[Format partition with ext4]"
losetup -D
LOOPDEVICE=$(losetup -f)
echo -e "\n[Using ${LOOPDEVICE} loop device]"
losetup -o $(expr 512 \* 2048) ${LOOPDEVICE} ./timos.img
mkfs.ext4 ${LOOPDEVICE}

echo_blue "[Copy timos directory structure to partition]"
mkdir -p ./mnt
mount -t auto ${LOOPDEVICE} ./mnt/
cp -R ./build/. ./mnt/

echo_blue "[Setup extlinux]"
extlinux --install ./mnt/boot/
cp -R ./syslinux.cfg ./mnt/boot/syslinux.cfg
sed -i "s|__ROOT__|${DRIVE}|g" ./mnt/boot/syslinux.cfg 
cp -R /usr/lib/syslinux/bios/isolinux.bin ./mnt/boot/syslinux.bin
cp -R /usr/lib/syslinux/bios/libcom32.c32 ./mnt/boot/
cp -R /usr/lib/syslinux/bios/libutil.c32 ./mnt/boot/
cp -R /usr/lib/syslinux/bios/ldlinux.c32 ./mnt/boot/
cp -R /usr/lib/syslinux/bios/menu.c32 ./mnt/boot/

echo_blue "[Unmount]"
umount ./mnt
losetup -D

echo_blue "[Write syslinux MBR]"
dd if=/usr/lib/syslinux/bios/mbr.bin of=./timos.img bs=440 count=1 conv=notrunc

echo_blue "[Convert to qcow2]"
qemu-img convert -c ./timos.img -O qcow2 ./timos.qcow2

echo "Done."
