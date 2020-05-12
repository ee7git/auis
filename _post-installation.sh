
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
    Option "XkbLayout" "latam,us,ru"
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
# Unmounting
#
# -----------------------------------------------------------------------------

announce "Unmounting partitions"
umount -R /mnt
check
