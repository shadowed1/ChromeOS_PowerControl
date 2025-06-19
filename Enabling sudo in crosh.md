# Enabling sudo in crosh shell

Created by velzie: https://gist.github.com/velzie <br>
Original Guide: https://gist.github.com/velzie/a5088c9ade6ec4d35435b9826b45d7a3 <br>

This is rewritten by shadowed1 to be a faster setup. Enabling sudo in crosh shell: <br>

1. Disable rootfs verification: Open VT-2 (ctrl-alt-forward), login as root, and run: <br>
`/usr/libexec/debugd/helpers/dev_features_rootfs_verification`. and **Reboot**. <br>

2. Launch **Crostini** and run: <br>
`sudo apt-get update` <br>
`sudo apt install gcc` enter y to install. <br>

3. In **Chrome (or browser of choice)**, download minioverride.c: <br>
https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/minioverride.c <br>
ctrl-s to save it in Linux Files as `minioverride.c` This saves it to /home/(yourname)/  <br>

4. Back in **Crostini**, type: `gcc ~/minioverride.c -o ~/minioverride.so -shared` <br>

5. In the **Chrome Files** app, copy `minioverride.so` from My Files/Linux Files into My Files/ <br>

6. Open **crosh shell (ctrl-alt-t)** and copy paste: <br>
`bash <(curl -s "https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/sudocrosh_downloader.sh?$(date +%s)")`

7. In **VT-2 (ctrl-alt-forward)** run:
`sudo mkdir -p /usr/local/bin`
`sudo mv /home/chronos/user/MyFiles/sc.sh /usr/local/bin`
`sudo bash /usr/local/bin/sc.sh`

After rebooting you should be able to use sudo inside crosh as you would normally before updating to 117. It will display the warning, but sudo should work regardless.

*Each time ChromeOS updates these changes are overwritten. Do step 1 and step 6 again. Keep a copy of your minioverride.c and .so handy.* 
