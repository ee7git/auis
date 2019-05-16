# Arch Unattended Installation Script (AUIS)

Just a personal down-to-script of the Arch Linux installation steps (https://wiki.archlinux.org/index.php/Installation_Guide)

After booting from the Arch Linux UEFI Live USB:

* Connect to the internet
* Install git
* Download the repo:

```shell
git clone https://github.com/ee7git/auis.git
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
