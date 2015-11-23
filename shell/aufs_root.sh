#!/bin/sh

# Add this shell to /etc/rc.local could make the OS "clean" after reboot.
# It could help to do some installation test on Linux.
#
# Please manually install two deb package and set dhclient before use it.
#   apt-get install apparmor-utils aufs-tools 
#   aa-complain dhclient
# 
# And you need to stop network-manager and use dhclient after reboot. Otherwise,
# the system may not get ip address.

log="/tmp/${0}.log"
rw_root="/rw_root"
if [ -f "$rw_root/1" ]; then
    exit 0
fi


rm -rf $rw_root
mkdir $rw_root

eclude_dirs="cdrom dev media mnt proc run tmp sys lost+found"
for path in `ls /`; do
    if [ -d "/$path" ]; then
        get=0
        for ex in $eclude_dirs; do
            if [ "$ex" = "$path" -o "/$path" = "$rw_root" ]; then
                get=1
            fi
        done

        if [ $get -eq 0 ]; then
            echo "Remount /$path" 
            mkdir "$rw_root/$path"
            mount -t aufs -o dirs="$rw_root/$path"=rw:"/$path"=ro "${path}.aufs" "/$path"
        fi
    fi
done
