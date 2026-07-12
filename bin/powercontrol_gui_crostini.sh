#!/bin/bash
sudo apt update
sudo apt install gedit gnome-themes-extra gnome-icon-theme -y
sudo apt install python3-gi gir1.2-gtk-3.0 python3-gi-cairo -y
sudo curl -fsSL https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/gui.py -o /bin/powercontrol-gui 2>/dev/null
sudo chmod +x /bin/powercontrol-gui 2>/dev/null
sudo mkdir -p /usr/share/applications/ /usr/share/icons/hicolor/48x48/apps/
cat <<'EOF' | sudo tee /usr/share/applications/powercontrol-gui.desktop > /dev/null
[Desktop Entry]
Version=1.0
Type=Application
Name=PowerControl
Comment=Get the power to control your CPU, Battery, Fan Curve, GPU, and Sleep for ChromeOS! 
Exec=/bin/powercontrol-gui
Icon=powercontrol
Terminal=false
Categories=Utility;System; 
StartupNotify=true
EOF
sudo curl -Ls https://github.com/shadowed1/ChromeOS_PowerControl/blob/main/icons/powercontrol_200p.png?raw=true -o /usr/share/icons/hicolor/48x48/apps/powercontrol.png
