

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

# -----------------------------------------------------------------------------
#
# Adding key language switchers
#
# -----------------------------------------------------------------------------

announce "Creating 00-keyboard.conf"
cat <<EOF > /mnt/etc/X11/xorg.conf.d/00-keyboard.conf
Section "InputClass"
    Identifier "keyboard languages"
    MatchIsKeyboard "on"
    Option "XkbLayout" "latam,ee,ru"
    Option "XkbModel" "pc104"
    Option "XkbVariant" ",,"
    Option "XkbOptions" "grp:alt_shift_toggle"
EndSection
EOF
check

# -----------------------------------------------------------------------------
#
# Dotfiles
#
# -----------------------------------------------------------------------------

announce "Loading dotfiles"
${ARCH_CHROOT} su -l "${CONF_USERNAME}" -c "git clone --single-branch --depth 1 --separate-git-dir=/home/${CONF_USERNAME}/.dotfiles https://github.com/wjes/dotfiles.git /home/${CONF_USERNAME}/tmp"
check

announce "Copying dotfiles"
${ARCH_CHROOT} su -l "${CONF_USERNAME}" -c "cp -a /home/${CONF_USERNAME}/tmp/. /home/${CONF_USERNAME}"
check

announce "Deleting dotfiles"
${ARCH_CHROOT} su -l "${CONF_USERNAME}" -c "rm -rf /home/${CONF_USERNAME}/tmp /home/${CONF_USERNAME}/.git /home/${CONF_USERNAME}/README.md"
check

announce "Loading bash-it"
${ARCH_CHROOT} su -l "${CONF_USERNAME}" -c "git clone --depth=1 https://github.com/Bash-it/bash-it.git ~/.bash_it && ~/.bash_it/install.sh --no-modify-config"
check

announce "Loading powerline fonts"
${ARCH_CHROOT} su -l "${CONF_USERNAME}" -c "git clone --depth=1 https://github.com/powerline/fonts.git && ./fonts/install.sh && rm -rf fonts"
check

announce "Installing Vim plug"
${ARCH_CHROOT} su -l "${CONF_USERNAME}" -c "vim +PlugInstall +qall > /dev/null"
check

# announce "Setting home files permissions"
# ${ARCH_CHROOT} find /home/${CONF_USERNAME} -type d -exec chmod 0750 {} +
# check
# 
# announce "Setting home directories permissions"
# ${ARCH_CHROOT} find /home/${CONF_USERNAME} -type f -exec chmod 0740 {} +
# check
# 
# announce "Setting home files & directories ownership"
# ${ARCH_CHROOT} chown -R ${CONF_USERNAME}:${CONF_USERNAME} /home/${CONF_USERNAME}/
# check

# -----------------------------------------------------------------------------
#
# MongoDB
#
# -----------------------------------------------------------------------------

announce "Downloading MongoDB"
${ARCH_CHROOT} su -l "${CONF_USERNAME}" -c "wget https://aur.archlinux.org/cgit/aur.git/snapshot/mongodb-bin.tar.gz"
check

announce "Extracting MongoDB"
${ARCH_CHROOT} su -l "${CONF_USERNAME}" -c "tar -xzvf mongodb-bin.tar.gz"
check

announce "Generating MongoDB package"
${ARCH_CHROOT} su -l "${CONF_USERNAME}" -c "cd mongodb-bin && makepkg -s"
check

announce "Installing MongoDB"
${ARCH_CHROOT} "cd mongodb-bin && pacman -U mongodb-bin-*.pkg.tar.xz"
check

announce "Deleting MongoDB directory"
${ARCH_CHROOT} "rm -rf mongodb-bin mongodb-bin.tar.gz"
check

announce "Installing MongoDB tools"
${ARCH_CHROOT} su -l "${CONF_USERNAME}" -c "wget https://aur.archlinux.org/cgit/aur.git/snapshot/mongodb-tools-bin.tar.gz"
check

announce "Extracting MongoDB tools"
${ARCH_CHROOT} su -l "${CONF_USERNAME}" -c "tar -xzvf mongodb-tools-bin.tar.gz"
check

announce "Generating MongoDB tools package"
${ARCH_CHROOT} su -l "${CONF_USERNAME}" -c "cd mongodb-tools-bin && makepkg -s"
check

announce "Installing MongoDB tools"
${ARCH_CHROOT} "cd mongodb-tools-bin && pacman -U mongodb-tools-bin-*.pkg.tar.xz"
check

announce "Deleting MongoDB tools directory"
${ARCH_CHROOT} "rm -rf mongodb-bin-tools mongodb-tools-bin.tar.gz"
check

# -----------------------------------------------------------------------------
#
# Unmounting
#
# -----------------------------------------------------------------------------

announce "Unmounting partitions"
umount -R /mnt
check
