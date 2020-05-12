
set -em
clear

# -----------------------------------------------------------------------------
# 
# Usage
#
# -----------------------------------------------------------------------------

 function usage()
 {
     echo "usage: $0 [-upass password ] [-rpass password ] [ -dd | --default-devices ] [ -r | --reboot ] [-h]"
 }

while [ "$1" != "" ]; do
    case $1 in
        -upass )                 shift
                                 USER_PASSWORD="${1}"
                                 ;;
        -rpass )                 shift
                                 ROOT_PASSWORD="${1}"
                                 ;;
        -dd | --default-devices ) DEFAULT_DEVICES="yes"
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

# -----------------------------------------------------------------------------
# 
# Helpers
#
# -----------------------------------------------------------------------------

ARCH_CHROOT='arch-chroot /mnt'

PID=$$

function announce {
    >&2 echo -e "\e[1m\e[97m[ \e[93mINIT\e[39m ] ${1}...\e[0m"
    LAST="${1}"
}

function check {
    if [[ $? -ne 0 ]]; then
        >&2 echo -e "\e[1m[ \e[31mFAIL\e[39m ] ${LAST} ${1}\e[0m"
        exit 1
    else
        >&2 echo -e "\e[1m[ \e[32mDONE\e[39m ] ${LAST} ${1}\e[0m"
    fi
}

function stop {
  kill -s STOP ${PID}
}

# -----------------------------------------------------------------------------
# 
# Welcome message
#
# -----------------------------------------------------------------------------

echo -e '\e[1m\e[36m
           _    _ _____  _____
      /\  | |  | |_   _|/ ____|
     /  \ | |  | | | | | (___
    / /\ \| |  | | | |  \___ \
   / ____ \ |__| |_| |_ ____) |
  /_/    \_\____/|_____|_____/

 https://github.com/wjes/auis
\e[0m'

source _pre-installation.sh
source _installation.sh
source _post-installation.sh

echo "Installation complete!"

if [[ ! -z ${REBOOT} ]]; then
    reboot
fi
