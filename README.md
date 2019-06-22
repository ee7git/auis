# Arch Unattended Installation Script (AUIS)

Just a personal down-to-script of the Arch Linux installation steps (https://wiki.archlinux.org/index.php/Installation_Guide) for my Samsung Chromebook 3

After booting from the Arch Linux UEFI Live USB:

* Connect to the internet
* Install git
* Download the repo:

```shell
git clone --branch chromebook --depth 1 --single-branch https://github.com/ee7git/auis.git
```
* Run the script:

```shell
# -upass : User password
# -rpass : Root password
# -dd    : Use default device (/dev/sda)
# -r     : Reboot after finshing
./install.sh [-upass <password>] [-rpass <password>] [-dd] [-r] [-h]
```
* Play with the cats!
