
# -----------------------------------------------------------------------------
#
# Checks
#
# -----------------------------------------------------------------------------

announce "Checking internet connectivity"
wget -q --tries=10 --timeout=20 --spider http://example.com/
check


announce "Disk managment
The automatic process assumed the following configuration:

disk1     
|-disk1p1       UEFI partition
|-disk1p2       root partition
disk2     
|-disk2p1       home partition

This will automatically partitionate, format and mount the different partitions." && echo 

read -sp "Automatic disk managment [y|n]: " AUTO_DISK_MANAGMENT && echo

if [[ ! -z "${AUTO_DISK_MANAGMENT}" && "${AUTO_DISK_MANAGMENT}" =~  ^(y|Y)$ ]]; then

  # -----------------------------------------------------------------------------
  #
  # Partitioning
  #
  # -----------------------------------------------------------------------------

  while
    announce "Listing blocks"
    lsblk -f && echo
    ead -sp "Enter device for UEFI and root partitions (default '/dev/nvme0n1')" DEVICE_UEFI_ROOT && echo
    [[ ! -d "${DEVICE_UEFI_ROOT}" && ! -z "${DEVICE_UEFI_ROOT}" ]]
  do
   	announce "The device does not exist!" && echo
  done
  check

  while
    announce "Listing blocks"
    lsblk -f && echo
    ead -sp "Enter device for home partition (default '/dev/sda')" DEVICE_HOME && echo
    [[ ! -d "${DEVICE_HOME}" && ! -z "${DEVICE_HOME}" ]]
  do
   	announce "The device does not exist!" && echo
  done
  check

  if [ -z ${DEVICE_UEFI_ROOT} ] ; then
  	announce "Setting device for UEFI and root partitions to default value '/dev/nvme0n1'!"
  	DEVICE_UEFI_ROOT="/dev/nvme0n1"
  fi
  
  if [ -z ${DEVICE_HOME} ] ; then
  	announce "Setting device for home partition to default value '/dev/sda'!"
  	DEVICE_HOME="/dev/sda"
  fi
  
  PART_UEFI="${DEVICE_UEFI_ROOT}1"
  PART_ROOT="${DEVICE_UEFI_ROOT}2"
  PART_HOME="${DEVICE_HOME}1"
  
  announce "Partitioning UEFI and root"
  sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | sudo gdisk "${DEVICE_UEFI_ROOT}"
  o     # clear the in memory partition table
  y     # yes
  n     # new partition
  1     # partition number 1
        # default - start at beginning of disk
  +512M # 512 MB UEFI parttion
  ef00  # EFI system
  n     # new partition
  2     # partion number 2
        # default, start immediately after preceding partition
        # default, extend partition to end of disk
  8304  # linux root x86_64 system
  p     # print the in-memory partition table
  w     # write the partition table
  y     # yes
EOF
  check
  
  # announce "Partitioning UEFI and root"
  # sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk "${DEVICE_UEFI_ROOT}"
  # g # clear the in memory partition table
  # n # new partition
  # 1 # partition number 1
  #   # default - start at beginning of disk
  # +512M # 512 MB UEFI parttion
  # n # new partition
  # 2 # partion number 2
  #   # default, start immediately after preceding partition
  #   # default, extend partition to end of disk
  # t # change UEFI partition type
  # 1 # partition number 1
  # 1 # to UEFI system
  # t # change root partition type
  # 2 # partion number 2
  # 22 # to linux root x86_64 system
  # p # print the in-memory partition table
  # w # write the partition table
  # EOF
  # check
  
  announce "Partitioning home"
  sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | sudo gdisk "${DEVICE_HOME}"
  o     # clear the in memory partition table
  y     # yes
  n     # new partition
  1     # partition number 1
        # default - start at beginning of disk
        # default, extend partition to end of disk
  8302  # linux home system
  p     # print the in-memory partition table
  w     # write the partition table
  y     # yes
EOF
  check
  
  # announce "Partitioning home"
  # sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk "${DEVICE_HOME}"
  # g # clear the in memory partition table
  # n # new partition
  # 1 # partition number 1
  #   # default - start at beginning of disk
  #   # default, extend partition to end of disk
  # t # change UEFI partition type
  # 1 # partition number 1
  # 28 # to home system
  # p # print the in-memory partition table
  # w # write the partition table
  # EOF
  # check
  
  # echo 'g
  # n
  # 1
  # 
  # +550M
  # t
  # 1
  # n
  # 2
  # 
  # 
  # t
  # 2
  # 22
  # w
  # ' | fdisk "${DEVICE}"
  

  # -----------------------------------------------------------------------------
  #
  # Formatting
  #
  # -----------------------------------------------------------------------------
  
  # announce "Installing dosfstools"
  # pacman -S --noconfirm dosfstools
  # check
  
  announce "Formatting UEFI partition"
  mkfs.fat -F32 "${PART_UEFI}"
  check
  
  announce "Formatting root partition"
  mkfs.ext4 "${PART_ROOT}"
  check
  
  announce "Formatting home partition"
  mkfs.ext4 "${PART_HOME}"
  check
  
  # -----------------------------------------------------------------------------
  #
  # Mounting
  #
  # -----------------------------------------------------------------------------
  
  announce "Mounting root partition"
  mount "${PART_ROOT}" /mnt
  check
  
  announce "Mounting UEFI partition"
  mkdir -p /mnt/efi
  mount "${PART_UEFI}" /mnt/efi
  check

  announce "Mounting home partition"
  mkdir -p /mnt/home
  mount "${PART_HOME}" /mnt/home
  check

  # -----------------------------------------------------------------------------
  #
  # SSD optimization
  #
  # -----------------------------------------------------------------------------

  announce "Adding SSD flags to fstab for root"
  ${ARCH_CHROOT} tune2fs -o discard "${PART_ROOT}"
  check
  
  announce "Adding SSD flags to fstab for home"
  ${ARCH_CHROOT} tune2fs -o discard "${PART_HOME}"
  check
  
  announce "Configuring SSD scheduler"
  cat <<EOF > /mnt/etc/udev/rules.d/60-schedulers.rules
# set scheduler for NVMe
ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
# set scheduler for SSD and eMMC
ACTION=="add|change", KERNEL=="sd[a-z]|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
# set scheduler for rotating disks
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
EOF
  check

else

  announce "Manual disk managment"
  while
    echo "The AUIS script will be suspended now. You'll have to manually partitionate, format and mount the different partitions of the system."
    echo "Ater that you can resume the AUIS script by typing the command 'fg'" 
    echo

    stop
    
    lsblk -f && echo
    read -sp "Is this correct? [y|n]: " YES && echo
    [[ ! -z "${YES}" && "${YES}" =~  ^(y|Y)$ ]]
  do
    clear  
  done
  check

fi

