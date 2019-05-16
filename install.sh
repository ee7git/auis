#!/bin/bash
# Last update May 14th 2019
#

set -e
clear

 function usage()
 {
     echo "usage: $0 [-upass password ] [-rpass password ] [ -dd | --default-device ] [ -r | --reboot ] [-h]"
 }

while [ "$1" != "" ]; do
    case $1 in
        -upass )                 shift
                                 USER_PASSWORD="${1}"
                                 ;;
        -rpass )                 shift
                                 ROOT_PASSWORD="${1}"
                                 ;;
        -dd | --default-device ) DEFAULT_DEVICE="yes"
                                 ;;
        -r | --reboot )          REBOOT="yes"
                                 ;;
        -h | --help )            usage
                                 exit
                                 ;;
        * )                      usage
                                 exit 1
    esac
    shift
done

function announce {
    >&2 echo -e "\e[1m\e[97m[ ${1} \e[93mSTART\e[39m ]\e[0m"
    last="${1}"
}
function check_fail {
    if [[ $? -ne 0 ]]; then
        >&2 echo -e "\e[1m[ ${last} \e[31mFAIL\e[39m ]\e[0m"
        exit 1
    else
        >&2 echo -e "\e[1m[ ${last} \e[32mDONE\e[39m ]\e[0m"
    fi
}

function welcome_banner {
echo -e '\e[1m\e[36m
           _    _ _____  _____
      /\  | |  | |_   _|/ ____|
     /  \ | |  | | | | | (___
    / /\ \| |  | | | |  \___ \
   / ____ \ |__| |_| |_ ____) |
  /_/    \_\____/|_____|_____/

 https://github.com/ee7git/auis
\e[0m'
}

HOSTNAME="arch-$(( ${RANDOM} % 100 ))-lan"
TIMEZONE="Chile/Continental"
MIRRORLIST_COUNTRY_NAME="Chile"
CONSOLE_KEYMAP="es"
USERNAME="warren"
LOCALE="es_CL"
LOCALE_LANG="en_GB"
UEFI_BOOTLOADER_NAME="Mohote"
PACKAGES_LIST=(
alsa-utils
atril
bash-completion
chromium
cups
cups-pdf
deadbeef
efibootmgr
eom
eslint
faenza-icon-theme
feh
firefox
flashplugin
gimp
git
grub
gvfs
gvfs-mtp
mesa-libgl
htop
i3lock
inkscape
lib32-libcups
lib32-mesa
lxappearance
make
mplayer
networkmanager
nodejs
npm
obconf
openbox
openssh
opera
p7zip
sudo
tar
mate-terminal
thunar
tint2
transmission-gtk
vim
unrar
unzip
wget
xcompmgr
xf86-video-intel
xorg-server
xorg-xinit
xss-lock
youtube-dl
zip
zsh
zsh-completions
$(pacman -Ssq "^ttf.*")
)
PACKAGES=$( IFS=$' '; echo "${PACKAGES_LIST[*]}" )
ARCH='arch-chroot /mnt'

welcome_banner

announce "Checking internet connectivity"
wget -q --tries=10 --timeout=20 --spider http://example.com/
check_fail

if [[ -z ${DEFAULT_DEVICE} ]]; then
    while
        announce "Listing blocks"
        lsblk -f && echo
    	read -sp "Enter device (default '/dev/sda')" DEVICE && echo
    	[[ ! -d "${DEVICE}" && ! -z "${DEVICE}" ]]
    do
        clear
    	announce "The device does not exist!" && echo
    done
    check_fail
fi

if [ -z ${DEVICE} ] ; then
	announce "Setting device to default value!"
	DEVICE="/dev/sda"
fi

PART_ROOT="${DEVICE}2"
PART_UEFI="${DEVICE}1"

announce "Formatting disk"
#fdisk "${DEVICE}"
echo 'g
n
1

+550M
t
1
n
2


t
2
22
w
' | fdisk "${DEVICE}"
check_fail

announce "Installing dosfstools"
pacman -S --noconfirm dosfstools
check_fail

announce "Formatting UEFI partition"
mkfs.fat -F32 "${PART_UEFI}"
check_fail

announce "Formatting root partition"
mkfs.ext4 -F "${PART_ROOT}"
check_fail

announce "Mounting root partition"
mount "${PART_ROOT}" /mnt
check_fail

announce "Mounting UEFI partition"
mkdir /mnt/efi
mount "${PART_UEFI}" /mnt/efi
check_fail

announce "Installing base system"
pacstrap /mnt base base-devel
check_fail

announce "Configuring fstab"
genfstab -U /mnt >> /mnt/etc/fstab
check_fail

announce "Setting root password"
if [[ -z "${ROOT_PASSWORD}" ]]; then
    while
        read -sp "Enter root password: " ROOT_PASSWORD && echo
        read -sp "Enter root password again: " RE_ROOT_PASSWORD && echo
        [[ "${ROOT_PASSWORD}" != "${RE_ROOT_PASSWORD}" || -z "${ROOT_PASSWORD}" ]]
    do
        echo "Passwords must be equal and not empty!"
    done
fi
echo "root:${ROOT_PASSWORD}" | ${ARCH} chpasswd
check_fail

announce "Setting hostname"
${ARCH} echo "${HOSTNAME}" > /etc/hostname
check_fail

announce "Setting timezone"
${ARCH} ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
check_fail

announce "Setting hwclock"
${ARCH} hwclock --systohc
check_fail

announce "Setting locales"
${ARCH} sed -i "s/#\(${LOCALE}\.UTF-8\)/\1/" /etc/locale.gen
check_fail

announce "Configuring locale.conf"
cat <<EOF >> /mnt/etc/locale.conf
LANG="${LOCALE_LANG}.UTF-8"
EOF
check_fail

announce "Configuring vconsole.conf"
cat <<EOF >> /mnt/etc/vconsole.conf
KEYMAP=${CONSOLE_KEYMAP}
EOF
check_fail

announce "Generating locales"
${ARCH} locale-gen
check_fail

announce "Setting pacman mirrors"
${ARCH} sed -i -n '1,/^$/p;/^$/,${/## '${MIRRORLIST_COUNTRY_NAME}'/!{/^$/!{s/## \(Server\)/\1/;H}};/## '${MIRRORLIST_COUNTRY_NAME}'/{N;s/## \(Server\)/\1/;p};${g;p}}' /etc/pacman.d/mirrorlist
check_fail

announce "Enabling multilib repository"
${ARCH} sed -i '/#\[multilib\]/{N;s/#\(.*\)\n#\(.*\)/\1\n\2/}' /etc/pacman.conf
check_fail

announce "Installing packages"
${ARCH} pacman -Syu --noconfirm ${PACKAGES}
check_fail

announce "Generating GRUB"
${ARCH} grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=${UEFI_BOOTLOADER_NAME}
check_fail

announce "Generating GRUB configuration"
${ARCH} grub-mkconfig -o /boot/grub/grub.cfg
check_fail

announce "Enabling networking"
${ARCH} systemctl enable NetworkManager.service
check_fail

announce "Creating user"
${ARCH} useradd -m ${USERNAME}
check_fail

announce "Setting user password"
if [[ -z "${USER_PASSWORD}" ]]; then
    while
        read -sp "Enter user password: " USER_PASSWORD && echo
        read -sp "Enter user password again: " RE_USER_PASSWORD && echo
        [[ "${USER_PASSWORD}" != "${RE_USER_PASSWORD}" || -z "${USER_PASSWORD}" ]]
    do
        echo "Passwords must be equal and not empty!"
    done
fi
echo "${USERNAME}:${USER_PASSWORD}" | ${ARCH} chpasswd
check_fail

announce "Adding user to sudoer"
${ARCH} sed -i "s/root \(ALL=(ALL) ALL\)/&\n${USERNAME} \1/" /etc/sudoers
check_fail

announce "Adding SSD flags to fstab"
${ARCH} tune2fs -o discard "${PART_ROOT}"
check_fail

announce "Configuring SSD scheduler"
cat <<EOF > /mnt/etc/udev/rules.d/60-schedulers.rules
# set deadline scheduler for non-rotating disks
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="deadline"
EOF
check_fail

announce "Fixing snd_hda_intel alsa issue"
cat <<EOF > /mnt/etc/modprobe.d/50-alsa.conf
options snd_hda_intel enable=1 index=0
options snd_hda_intel index=1
EOF
check_fail

announce "Creating 00-keyboard.conf"
cat <<EOF > /mnt/etc/X11/xorg.conf.d/00-keyboard.conf
Section "InputClass"
    Identifier "keyboard languages"
    MatchIsKeyboard "on"
    Option "XkbLayout" "latam,us,ru"
    Option "XkbModel" "pc104"
    Option "XkbVariant" ",,"
    Option "XkbOptions" "grp:alt_shift_toggle"
EndSection
EOF
check_fail

announce "Configuring logind triggers"
${ARCH} sed -i 's/#\(Handle\(PowerKey\|LidSwitch\(ExternalPower\|Docked\)\?\)=\).*/\1lock/' /etc/systemd/logind.conf
check_fail

announce "Loading dotfiles"
${ARCH} git clone --separate-git-dir=/home/${USERNAME}/.dotfiles https://github.com/ee7git/dotfiles.git /home/${USERNAME}/tmp
check_fail

announce "Copying dotfiles"
${ARCH} cp -a /home/${USERNAME}/tmp/. /home/${USERNAME}
check_fail

announce "Deleting dotfiles"
${ARCH} rm -rf /home/${USERNAME}/tmp /home/${USERNAME}/.git /home/${USERNAME}/README.md
check_fail

announce "Configuring mate-terminal"
mv -f /mnt/home/${USERNAME}/dconf.conf .
cat dconf.conf | ${ARCH} dconf load /
check_fail

announce "Installing Vim plug"
${ARCH} su ${USERNAME} -c 'vim +PlugInstall +qall > /dev/null'
check_fail

announce "Setting home files permissions"
${ARCH} find /home/${USERNAME} -type d -exec chmod 0750 {} +
check_fail

announce "Setting home directories permissions"
${ARCH} find /home/${USERNAME} -type f -exec chmod 0740 {} +
check_fail

announce "Setting home files & directories ownership"
${ARCH} chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/
check_fail

announce "Unmounting partitions"
umount -R /mnt
check_fail

echo "Installation complete!"

if [[ ! -z ${REBOOT} ]]; then
    reboot
fi
