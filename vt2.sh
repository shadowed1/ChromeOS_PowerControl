#!/bin/bash
mkdir -p /usr/local/bin
mv /home/chronos/user/Downloads/minioverride.so /usr/local/bin/
chmod +x /usr/local/bin/minioverride.so
sed -i '1s/^/env LD_PRELOAD=\/usr\/local\/bin\/minioverride.so\n/' /etc/init/ui.conf 
echo "Reboot and sudo in crosh shell should be enabled!"
