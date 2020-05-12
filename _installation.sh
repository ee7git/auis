
# -----------------------------------------------------------------------------
#
# Variables
#
# -----------------------------------------------------------------------------

CONF_HOSTNAME="awd"
CONF_TIMEZONE="Chile/Continental"
CONF_MIRRORLIST_COUNTRY_NAME="Chile"
CONF_USERNAME="warren"
CONF_LOCALE="es_CL"
CONF_LOCALE_LANG="en_GB"
CONF_CONSOLE_KEYMAP="es"
CONF_UEFI_BOOTLOADER_NAME="ARCH"
CONF_PACSTRAP_PACKAGES_LIST=(
base
base-devel
linux 
linux-firmware
vim 
git
networkmanager
man-db
man-pages
grub
efibootmgr
sudo
)
CONF_PACKAGES_LIST=(
alsa-utils
atril
bash-completion
chromium
cups
cups-pdf
deadbeef
eom
eslint
faenza-icon-theme
feh
firefox
flashplugin
gimp
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
nodejs
npm
obconf
openbox
openssh
opera
p7zip
prettier
tar
terminator
thunar
tint2
transmission-gtk
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
ttf-anonymous-pro
ttf-dejavu
ttf-liberation
ttf-linux-libertine
ttf-linux-libertine-g
ttf-roboto
ttf-roboto-mono
ttf-ubuntu-font-family
)
CONF_PACSTRAP_PACKAGES=$( IFS=$' '; echo "${PACKAGES_LIST[*]}" )
CONF_PACKAGES=$( IFS=$' '; echo "${PACKAGES_LIST[*]}" )

# -----------------------------------------------------------------------------
#
# Install base system
#
# -----------------------------------------------------------------------------

announce "Installing base system"
pacstrap /mnt ${CONF_PACSTRAP_PACKAGES}
check

# -----------------------------------------------------------------------------
#
# Configurations
#
# -----------------------------------------------------------------------------

announce "Setting hostname"
${ARCH_CHROOT} echo "${CONF_HOSTNAME}" > /etc/hostname
check

announce "Setting locales"
${ARCH_CHROOT} sed -i "s/#\(${CONF_LOCALE}\.UTF-8\)/\1/" /etc/locale.gen
check

announce "Creating locale.conf"
${ARCH_CHROOT} echo "LANG=${CONF_LOCALE_LANG}.UTF-8" > /etc/locale.conf
check

announce "Creating vconsole.conf"
${ARCH_CHROOT} echo "KEYMAP=${CONF_CONSOLE_KEYMAP}" > /etc/vconsole.conf
check

announce "Generating locales"
${ARCH_CHROOT} locale-gen
check

announce "Setting timezone"
${ARCH_CHROOT} ln -sf /usr/share/zoneinfo/${CONF_TIMEZONE} /etc/localtime
check

announce "Setting hwclock"
${ARCH_CHROOT} hwclock --systohc
check

announce "Setting pacman mirrors"
# TODO redo this woth awk
${ARCH_CHROOT} sed -i -n '1,/^$/p;/^$/,${/## '${CONF_MIRRORLIST_COUNTRY_NAME}'/!{/^$/!{s/## \(Server\)/\1/;H}};/## '${CONF_MIRRORLIST_COUNTRY_NAME}'/{N;s/## \(Server\)/\1/;p};${g;p}}' /etc/pacman.d/mirrorlist
check

announce "Enabling multilib repository"
${ARCH_CHROOT} sed -i '/#\[multilib\]/{N;s/#\(.*\)\n#\(.*\)/\1\n\2/}' /etc/pacman.conf
check

announce "Configuring fstab"
genfstab -U /mnt >> /mnt/etc/fstab
check

announce "Generating GRUB"
${ARCH_CHROOT} grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=${CONF_UEFI_BOOTLOADER_NAME}
check

announce "Generating GRUB configuration"
${ARCH_CHROOT} grub-mkconfig -o /boot/grub/grub.cfg
check

announce "Enabling networking"
${ARCH_CHROOT} systemctl enable NetworkManager.service
check

# -----------------------------------------------------------------------------
#
# Users
#
# -----------------------------------------------------------------------------

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
echo "root:${ROOT_PASSWORD}" | ${ARCH_CHROOT} chpasswd
check

announce "Creating user"
${ARCH_CHROOT} useradd -m ${USERNAME}
check

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
echo "${USERNAME}:${USER_PASSWORD}" | ${ARCH_CHROOT} chpasswd
check

announce "Adding user to sudoer"
${ARCH_CHROOT} sed -i "s/root \(ALL=(ALL) ALL\)/&\n${USERNAME} \1/" /etc/sudoers
check

# -----------------------------------------------------------------------------
#
# Installing packages
#
# -----------------------------------------------------------------------------

announce "Installing packages"
${ARCH_CHROOT} su -l "${CONF_USERNAME}" -c "sudo pacman -Syu --noconfirm ${CONF_PACKAGES}"
check

