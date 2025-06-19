# Enabling sudo in crosh shell

Created by velzie: https://gist.github.com/velzie <br>
Original Guide: https://gist.github.com/velzie/a5088c9ade6ec4d35435b9826b45d7a3 <br>

This is rewritten by shadowed1 to be a faster setup. Enabling sudo in crosh shell: <br>

1. Disable rootfs verification: Open VT-2 (ctrl-alt-forward), login as root, and run: <br>
`/usr/libexec/debugd/helpers/dev_features_rootfs_verification`. and Reboot. <br>

2. Launch Crostini and run:
`sudo apt-get update`
`sudo apt install gcc` enter y to install.

3. In Chrome, download minioverride.c:
https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/minioverride.c
place it in My Files/Linux Files.

4. Back in crostini, type: `cd

In the files app, move `minioverride.so` into your downloads folder.

Switch to vt2, and in the root terminal, *not crostini*, run these commands

```bash
mkdir -p /usr/local/bin
mv /home/chronos/user/Downloads/minioverride.so /usr/local/bin/
chmod +x /usr/local/bin/minioverride.so
sed -i '1s/^/env LD_PRELOAD=\/usr\/local\/bin\/minioverride.so\n/' /etc/init/ui.conf 
reboot
```

After rebooting you should be able to use sudo inside crosh as you would normally before updating to 117. It will display the warning, but sudo should work regardless.


**NOTE:**
When you update chrome os versions, this will stop working. You don't need to redo the whole thing, just run `/usr/libexec/debugd/helpers/dev_features_rootfs_verification`, reboot and run `sed -i '1s/^/env LD_PRELOAD=\/usr\/local\/bin\/minioverride.so\n/' /etc/init/ui.conf` and reboot again.

1/29 - added fix for landlock policy (fixes permission denied writing to disk)
restart the entire process with the updated c code if you want to fix it
