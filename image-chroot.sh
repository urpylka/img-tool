#! /usr/bin/env bash

#
# image-chroot.sh – script for execute commands in file-image, copy files
# Copyright 2018 Artem B. Smirnov
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e # Exit immidiately on non-zero result

echo_stamp() {
  # TEMPLATE: echo_stamp <TEXT> <TYPE>
  # TYPE: SUCCESS, ERROR, INFO

  # More info there https://www.shellhacks.com/ru/bash-colors/

  TEXT="$(date '+[%Y-%m-%d %H:%M:%S]') $1"
  TEXT="\e[1m$TEXT\e[0m" # BOLD

  case "$2" in
    SUCCESS)
    TEXT="\e[32m${TEXT}\e[0m";; # GREEN
    ERROR)
    TEXT="\e[31m${TEXT}\e[0m";; # RED
    *)
    TEXT="\e[34m${TEXT}\e[0m";; # BLUE
  esac
  echo -e ${TEXT}
}

# This script doesn't work on Ubuntu because OS`s losetup does not consist --partscan (-P).

# Idea: use `mount -o loop,offset`
# https://stefanoprenna.com/blog/2014/09/22/tutorial-how-to-mount-raw-images-img-images-on-linux/
# REPO_DIR=$(mktemp -d --suffix=.builder_repo)
# mount -t ext4 -o loop,offset=$((94208 * 512)) image/clever_qemu_test_2_20180822_163141.img "$REPO_DIR"
# mount -t vfat -o loop,offset=$((8192 * 512)) image/clever_qemu_test_2_20180822_163141.img "$REPO_DIR/boot"

execute() {
  # execute <IMAGE_PATH> [<EXECUTE_FILE> [...]]

  echo_stamp "Mount loop-image: $1"
  local DEV_IMAGE=$(losetup -Pf $1 --show)
  sleep 0.5

  local MOUNT_POINT=$(mktemp -d --suffix=.builder_image)
  echo_stamp "Mount dirs ${MOUNT_POINT} & ${MOUNT_POINT}/boot"
  mount "${DEV_IMAGE}p2" ${MOUNT_POINT}
  mount "${DEV_IMAGE}p1" ${MOUNT_POINT}/boot

  REGISTER=':arm:M::\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x28\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-wrapper:'
  if [[ $(arch) != 'armv7l' ]]; then
    echo_stamp "Enable qemu-arm-static"
    mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc 2> /dev/null || true
    echo ${REGISTER} > /proc/sys/fs/binfmt_misc/register 2> /dev/null || true
    cp './qemu-wrapper' "${MOUNT_POINT}/usr/bin/qemu-wrapper"
    cp './qemu-arm-static' "${MOUNT_POINT}/usr/bin/qemu-arm-static"
  else echo_stamp "qemu-arm-static is not need"
  fi

  echo_stamp "Bind system dirs"

  echo_stamp "Mounting /proc in chroot... "
  if [ ! -d ${MOUNT_POINT}/proc ]; then
    mkdir -p ${MOUNT_POINT}/proc; fi
  mount -t proc -o nosuid,noexec,nodev proc ${MOUNT_POINT}/proc \
  && echo_stamp "OK" "SUCCESS" \
  || (echo_stamp "Failed" "ERROR"; exit 1)

  echo_stamp "Mounting /sys in chroot... "
  if [ ! -d ${MOUNT_POINT}/sys ]; then
    mkdir -p ${MOUNT_POINT}/sys; fi
  mount -t sysfs -o nosuid,noexec,nodev sysfs ${MOUNT_POINT}/sys \
  && echo_stamp "OK" "SUCCESS" \
  || (echo_stamp "Failed" "ERROR"; exit 1)

  echo_stamp "Mounting /dev/ and /dev/pts in chroot... " \
  && mkdir -p -m 755 ${MOUNT_POINT}/dev/pts \
  && mount -t devtmpfs -o mode=0755,nosuid devtmpfs ${MOUNT_POINT}/dev \
  && mount -t devpts -o gid=5,mode=620 devpts ${MOUNT_POINT}/dev/pts \
  && echo_stamp "OK" "SUCCESS" \
  || (echo_stamp "Failed" "ERROR"; exit 1)

  echo_stamp "Copy DNS records" \
  && cp -L /etc/resolv.conf ${MOUNT_POINT}/etc/resolv.conf \
  && echo_stamp "OK" "SUCCESS" \
  || (echo_stamp "Failed" "ERROR"; exit 1)

  if [[ $# > 1 ]]; then
    echo_stamp "Copy script to chroot fs"

    local SCRIPT_NAME="$(basename $2).$(tr -dc 'A-F0-9' < /dev/urandom | dd bs=1 count=7 2>/dev/null)"
    local SCRIPT_DIR="${MOUNT_POINT}/root"

    cp "$2" "${SCRIPT_DIR}/${SCRIPT_NAME}"
    # Run script in chroot with additional arguments
    chroot ${MOUNT_POINT} /bin/sh -c "/root/${SCRIPT_NAME} $3 $4 $5 $6 $7"
    # Removing script from chroot fs
    rm "${SCRIPT_DIR}/${SCRIPT_NAME}"
  else
    # https://wiki.archlinux.org/index.php/Change_root_(%D0%A0%D1%83%D1%81%D1%81%D0%BA%D0%B8%D0%B9)
    # http://www.unix-lab.org/posts/chroot/
    # https://habrahabr.ru/post/141012/
    # https://losst.ru/vosstanovlenie-grub2
    # http://unixteam.ru/content/virtualizaciya-ili-zapuskaem-prilozhenie-v-chroot-okruzhenii-razmyshleniya
    # http://help.ubuntu.ru/wiki/%D0%B2%D0%BE%D1%81%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BB%D0%B5%D0%BD%D0%B8%D0%B5_grub
    echo_stamp "Entering chroot" \
    && chroot ${MOUNT_POINT} /bin/bash
  fi

  umount_system ${MOUNT_POINT} ${DEV_IMAGE}
}

umount_system() {
  # TEMPLATE: umount_system <MOUNT_POINT> <DEV_IMAGE>

  echo_stamp "Unmount chroot rootfs and boot partition: $1"
  umount_ok=false
  # Repeat 5 times
  for i in {1..5}; do
    umount -fR $1 \
    && umount_ok=true && break \
    || (echo_stamp "Failed #$i (try 5 times)" "ERROR"; echo "$1 is still used by the following processes: "; lsof +D $1; sleep 2)
  done
  [[ "$umount_ok" == true ]] && echo_stamp "OK" "SUCCESS" \
  || (echo_stamp "Umount loop-image was failed" "ERROR"; exit 1)
  losetup -d $2
}

copy_to_chroot() {
  # copy_to_chroot <IMAGE_PATH> <MOVE_FILE> <MOVE_TO>

  echo_stamp "Mount loop-image: $1"
  local DEV_IMAGE=$(losetup -Pf $1 --show)
  sleep 0.5

  local MOUNT_POINT=$(mktemp -d --suffix=.builder_image)
  echo_stamp "Mount dirs ${MOUNT_POINT} & ${MOUNT_POINT}/boot"
  mount "${DEV_IMAGE}p2" ${MOUNT_POINT}
  mount "${DEV_IMAGE}p1" ${MOUNT_POINT}/boot

  local dir_name=$(dirname "${MOUNT_POINT}$3 /")
  
  if [[ -f $2 ]]; then
    [[ ! -d ${dir_name} ]] && mkdir -p ${dir_name} \
    && echo_stamp "Created ${dir_name}" "SUCCESS"
  fi

  cp -r "$2" "${MOUNT_POINT}$3"
  umount_system ${MOUNT_POINT} ${DEV_IMAGE}
}

if [ $(whoami) != "root" ]; then
  echo ""
  echo "********************************************************************"
  echo "******************** This should be run as root ********************"
  echo "********************************************************************"
  echo ""
  exit 1
fi

echo "================================================================================"
for ((i=0; i<=$#; i++)); do echo "\$$i: ${!i}"; done
echo "================================================================================"

if [[ $# > 0 ]]; then
  [[ -f $1 ]] || (echo_stamp "$1 does not exist" "ERROR"; echo "Template: image-chroot.sh <IMAGE> [ exec <SCRIPT> [...] | copy <MOVE_FILE> <MOVE_TO> ]"; exit 1)

  if [[ ! -z $2 ]]; then
    case "$2" in
      exec)
        execute $1 $3 ${@:4};;
      copy)
        copy_to_chroot $1 $3 $4;;
      *)
        echo "Template: image-chroot.sh <IMAGE> [ exec <SCRIPT> [...] | copy <MOVE_FILE> <MOVE_TO> ]";;
    esac
  else execute $1; fi
fi
