#!/bin/sh

###############################################################################
#
# configure-AWS-client.sh    ver 3.07
#
# Author: mart
# Date 10/01/2020
#
# Configures a fresh installation of Xubuntu to convert it into a kiosk which
# only runs a workspacesclient application . A user is created, named
# kiosk, whose account can only be accessed by automatically launching an X
# session (password is disabled). That X session doesn't include any desktop
# environment.
#
# Usage: Launch as root (or with root permissions):
#   $ sudo ./install.sh
#
#   Tested on:
#
#       Xubuntu 18.04.5
#
###############################################################################

readonly KIOSK_AUTOLOGIN="\
[daemon]\n\
WaylandEnable=false\n\
AutomaticLoginEnable = true\n\
AutomaticLogin = kiosk\n\n\
[security]\n\n\
[xdmcp]\n\n\
[chooser]\n\n\
[debug]\n"

readonly KIOSK_DEFAULT_SESSION="\
[InputSource0]\n\
xkb=us\n\n\
[User]\n\
XSession=kiosk\n\
SystemAccount=false\n"

readonly KIOSK_GNOME_SESSION="\
[GNOME Session]\n\
Name=Zero Session\n\
RequiredComponents=workspacesclient;kiosk-shell;\n"

readonly KIOSK_SHELL="\
[Desktop Entry]\n\
Exec=gnome-shell --mode=kiosk\n"

readonly KIOSK_AWS="\
[Desktop Entry]\n\
Type=Application\n\
Encoding=UTF-8\n\
Name=Amazon WorkSpaces\n\
Comment=Amazon WorkSpaces\n\
Exec=/opt/workspacesclient/workspacesclient %u\n\
Path=/opt/workspacesclient\n\
Icon=com.amazon.workspaces\n\
Terminal=false\n\
MimeType=x-scheme-handler/workspaces;\n\
Categories=Network;RemoteAccess;\n\
Keywords=workspaces;remote;amazon;aws;\n\
StartupWMClass=workspacesclient"

readonly KIOSK_XSESSION="\
[Desktop Entry]\n\
Type=Application\n\
Encoding=UTF-8\n\
Name=Amazon WorkSpaces\n\
Comment=Amazon WorkSpaces\n\
Exec=gnome-session --session kiosk\n"

###############################################################################

# Configuration steps
do_install_aws_ws_client=y
do_create_kiosk_user=y
do_create_kiosk_xsession=y
do_enable_kiosk_autologin=y
do_fix_kiosk_X11=y

###############################################################################

###############################################################################

create_kiosk_user() {
    getent group kiosk || (
        groupadd kiosk
        useradd kiosk -s /bin/bash -m -g kiosk -p '*'
        passwd -d kiosk 
        passwd -l kiosk
    )
}

###############################################################################

create_kiosk_xsession() {
    echo $KIOSK_XSESSION > /usr/share/xsessions/kiosk.desktop
}

###############################################################################

install_aws_ws_client() {
        wget -q -O - https://workspaces-client-linux-public-key.s3-us-west-2.amazonaws.com/ADB332E7.asc | sudo apt-key add -
        echo "deb [arch=amd64] https://d3nt0h4h6pmmc4.cloudfront.net/ubuntu bionic main" | sudo tee /etc/apt/sources.list.d/amazon-workspaces-clients.list
        apt-get update
        apt-get install -y workspacesclient
}

###############################################################################

enable_kiosk_autologin() {
    echo $KIOSK_AUTOLOGIN > /etc/gdm3/custom.conf
    echo $KIOSK_DEFAULT_SESSION > /var/lib/AccountsService/users/kiosk
    echo $KIOSK_GNOME_SESSION > /usr/share/gnome-session/sessions/kiosk.session
    echo $KIOSK_SHELL > /usr/share/applications/kiosk-shell.desktop
}

###############################################################################

fix_kiosk_X11() {
cat  >/etc/X11/xorg.conf <<EOL
Section "ServerFlags" 
    Option "DontVTSwitch" "true"
    Option "DontZap"      "yes"
EndSection
EOL
}

###############################################################################
# Start execution
###############################################################################
# Provide an opportunity to stop installation

if [ $do_install_aws_ws_client = "y" ]; then
    install_aws_ws_client
fi

if [ $do_create_kiosk_user = "y" ]; then
    create_kiosk_user
fi

if [ $do_create_kiosk_xsession = "y" ]; then
    create_kiosk_xsession
fi

if [ $do_enable_kiosk_autologin = "y" ]; then
    enable_kiosk_autologin
fi

if [ $do_fix_kiosk_X11 = "y" ]; then
    fix_kiosk_X11
fi

exit 0

###############################################################################
# End execution
###############################################################################