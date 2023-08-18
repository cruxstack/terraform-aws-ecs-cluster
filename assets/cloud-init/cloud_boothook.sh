#!/usr/bin/env bash
# shellcheck disable=SC2207,SC2128,SC2046,SC2206,SC2155,SC2068

# --- configurations --------------------------

export RAID_NAME=ephemeral_raid
export RAID_DEVICE=/dev/md0
export RAID_MOUNT_PATH=/var/lib/docker

# --- functions -------------------------------

function list_instance_stores {
  if [[ -e /dev/nvme0n1 ]]; then
    local instance_stores=($(nvme list | awk '/Instance Storage/ {print $1}'))
  else
    local OSDEVICE=$(sudo lsblk -o NAME -n | grep -v '[[:digit:]]' | sed "s/^sd/xvd/g")
    local BDMURL="http://169.254.169.254/latest/meta-data/block-device-mapping/"
    local instance_stores=()
    for bd in $(curl -s ${BDMURL}); do
      MAPDEVICE=$(curl -s ${BDMURL}/"${bd}"/ | sed "s/^sd/xvd/g");
      if grep -wq "${MAPDEVICE}" <<< "${OSDEVICE}"; then
        instance_stores+=(${MAPDEVICE})
      fi
    done
  fi
  echo "${instance_stores[@]}"
}
export -f list_instance_stores


function provision_instance_stores {
  devices=($(list_instance_stores))
  count=${#devices[@]}

  mkdir -p ${RAID_MOUNT_PATH}
  if [[ ${count} -eq 1 ]]; then
    mkfs.ext4 "${devices}"
    echo "${devices}" ${RAID_MOUNT_PATH} ext4 defaults,noatime 0 2 >> /etc/fstab
  elif [[ ${count} -gt 1 ]]; then
    mdadm --create --verbose --level=0 ${RAID_DEVICE} --auto=yes --name=${RAID_NAME} --raid-devices="${count}" ${devices[@]}
    while [[ $(mdadm -D ${RAID_DEVICE}) != *"State : clean"* ]] && [[ $(mdadm -D $RAID_DEVICE) != *"State : active"* ]]; do
      sleep 1
    done
    mkfs.ext4 ${RAID_DEVICE}
    mdadm --detail --scan >> /etc/mdadm.conf
    dracut -H -f /boot/initramfs-$(uname -r).img $(uname -r)
    echo ${RAID_DEVICE} ${RAID_MOUNT_PATH} ext4 defaults,noatime 0 2 >> /etc/fstab
  fi
  mount -a
}
export -f provision_instance_stores

# --- script ----------------------------------

yum install -y mdadm nvme-cli
cloud-init-per once provision_instance_stores provision_instance_stores
