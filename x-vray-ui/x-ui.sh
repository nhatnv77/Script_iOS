#! /bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# check root
[[ $EUID-ne 0]]&&echo-e "${red} Error: ${plain} This script must be run with the root user! \n" && exit 1

# check os
if [[ -f /etc/redhat-release ]]; then
release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
release="centos"
else
echo-e "${red} The system version has not been detected, please contact the script author! ${plain}\n" && exit 1
fi

os_version=""

# os version
if [[ -f /etc/os-release ]]; then
os_version=$(awk -F'[= . "]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
os_version=$(awk -F'[= . "]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
if [[ ${os_version} -le 6 ]]; then
echo-e "${red} Please use CentOS 7 or later system! ${plain}\n" && exit 1
fi
elif [[ x"${release}" == x"ubuntu" ]]; then
if [[ ${os_version} -lt 16 ]]; then
echo-e "${red} Please use Ubuntu 16 or later system! ${plain}\n" && exit 1
fi
elif [[ x"${release}" == x"debian" ]]; then
if [[ ${os_version} -lt 8 ]]; then
echo-e "${red} Please use a system with Debian 8 or later! ${plain}\n" && exit 1
fi
fi

confirm() {
if [[ $# > 1 ]]; then
echo&& read-p "$1 [default$2]: "temp
if [[ x"${temp}" == x"" ]]; then
temp=$2
fi
else
read -p "$1 [y/n]: " temp
fi
if [[ x"${temp}" == x"y" || x"${temp}" == x"Y" ]]; then
return 0
else
return 1
fi
}

confirm_restart() {
confirm "Whether to restart the panel, restarting the panel will also restart xray""y"
if [[ $? == 0 ]]; then
restart
else
show_menu
fi
}

before_show_menu() {
echo&&echo-n-e"${yellow} Press enter to return to the main menu: ${plain}"&&read temp
show_menu
}

install() {
bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)
if [[ $? == 0 ]]; then
if [[ $# == 0 ]]; then
start
else
start 0
fi
fi
}

update() {
confirm "This function will force the current latest version to be reinstalled, and the data will not be lost. Will it continue? " "n"
if [[ $? ! = 0 ]]; then
echo-e "${red} has been cancelled${plain}"
if [[ $# == 0 ]]; then
before_show_menu
fi
return 0
fi
bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)
if [[ $? == 0 ]]; then
echo-e "更新{green} Update is complete, the panel has been automatically restarted${plain}"
exit 0
fi
}

uninstall() {
confirm "Are you sure you want to uninstall the panel, xray will also uninstall it? " "n"
if [[ $? ! = 0 ]]; then
if [[ $# == 0 ]]; then
show_menu
fi
return 0
fi
systemctl stop x-ui
systemctl disable x-ui
rm /etc/systemd/system/x-ui. service -f
systemctl daemon-reload
systemctl reset-failed
rm /etc/x-ui/ -rf
rm /usr/local/x-ui/ -rf

echo ""
echo-e "The uninstall was successful, if you want to delete this script, then exit the script and run ${green}rm/usr/bin/x-ui-f{{plain}to delete"
echo ""

if [[ $# == 0 ]]; then
before_show_menu
fi
}

reset_user() {
confirm "Are you sure you want to reset the username and password to admin?" "n"
if [[ $? ! = 0 ]]; then
if [[ $# == 0 ]]; then
show_menu
fi
return 0
fi
/usr/local/x-ui/x-ui setting -username admin -password admin
echo-e "The username and password have been reset to ${green}admin${plain}, please restart the panel now"
confirm_restart
}

reset_config() {
confirm "Are you sure you want to reset all panel settings? The account data will not be lost, and the user name and password will not be changed" "n"
if [[ $? ! = 0 ]]; then
if [[ $# == 0 ]]; then
show_menu
fi
return 0
fi
/usr/local/x-ui/x-ui setting -reset
echo-e "All panel settings have been reset to the default values, please restart the panel now and use the default 端口{green}54321{{plain} port to access the panel"
confirm_restart
}

set_port() {
echo&& echo-n-e " Enter the port number [1-65535]: "&& read port
if [[ -z "${port}" ]]; then
echo-e "${yellow} has been cancelled${plain}"
before_show_menu
else
/usr/local/x-ui/x-ui setting -port ${port}
echo-e "After setting the port, please restart the panel now and use the newly set port ${green}${port}${plain}to access the panel"
confirm_restart
fi
}

start() {
check_status
if [[ $? == 0 ]]; then
echo ""
echo-e "The面板{green} panel is already running, no need to start again, if you need to restart, please select restart${plain}"
else
systemctl start x-ui
sleep 2
check_status
if [[ $? == 0 ]]; then
echo-e"${green}x-ui started successfully${plain}"
else
echo-e "The面板{red} panel failed to start, probably because the startup time exceeded two seconds, please check the log information later${plain}"
fi
fi

if [[ $# == 0 ]]; then
before_show_menu
fi
}

stop() {
check_status
if [[ $? == 1 ]]; then
echo ""
echo-e "The${green} panel has stopped, there is no need to stop${plain} again"
else
systemctl stop x-ui
sleep 2
check_status
if [[ $? == 1 ]]; then
echo-e "${green}x-ui and xray stopped successfully${plain}"
else
echo-e "The面板{red} panel failed to stop, probably because the stop time exceeded two seconds, please check the log information later${plain}"
fi
fi

if [[ $# == 0 ]]; then
before_show_menu
fi
}

restart() {
systemctl restart x-ui
sleep 2
check_status
if [[ $? == 0 ]]; then
echo-e "${green} x-ui and xray restarted successfully${plain}"
else
echo-e "The面板{red} panel failed to restart, probably because the startup time exceeded two seconds, please check the log information later${plain}"
fi
if [[ $# == 0 ]]; then
before_show_menu
fi
}

status() {
systemctl status x-ui -l
if [[ $# == 0 ]]; then
before_show_menu
fi
}

enable() {
systemctl enable x-ui
if [[ $? == 0 ]]; then
echo-e "${green}x-ui set to boot successfully${plain}"
else
echo-e "${red}x-ui setting failed to boot from startup${plain}"
fi

if [[ $# == 0 ]]; then
before_show_menu
fi
}

disable() {
systemctl disable x-ui
if [[ $? == 0 ]]; then
echo-e "${green}x-ui cancel boot and self-start successfully${plain}"
else
echo-e"${red}x-ui cancels the boot and fails to start${plain}"
fi

if [[ $# == 0 ]]; then
before_show_menu
fi
}

show_log() {
journalctl -u x-ui. service -e --no-pager -f
if [[ $# == 0 ]]; then
before_show_menu
fi
}

migrate_v2_ui() {
/usr/local/x-ui/x-ui v2-ui

before_show_menu
}

install_bbr() {
# temporary workaround for installing bbr
bash <(curl -L -s https://raw.githubusercontent.com/teddysun/across/master/bbr.sh)
echo ""
before_show_menu
}

update_shell() {
wget -O /usr/bin/x-ui -N --no-check-certificate https://github.com/vaxilu/x-ui/raw/master/x-ui.sh
if [[ $? ! = 0 ]]; then
echo ""
echo-e "${red} Failed to download the script, please check whether this function is connected to Github${plain}"
before_show_menu
else
chmod +x /usr/bin/x-ui
echo-e "${green} The upgrade script was successful, please re-run the script${plain}"&&exit 0
fi
}

# 0: running, 1: not running, 2: not installed
check_status() {
if [[ ! -f /etc/systemd/system/x-ui. service ]]; then
return 2
fi
temp=$(systemctl status x-ui | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
if [[ x"${temp}" == x"running" ]]; then
return 0
else
return 1
fi
}

check_enabled() {
temp=$(systemctl is-enabled x-ui)
if [[ x"${temp}" == x"enabled" ]]; then
return 0
else
return 1;
fi
}

check_uninstall() {
check_status
if [[ $? ! = 2 ]]; then
echo ""
echo-e "The${red} panel is installed, please do not install${plain} repeatedly"
if [[ $# == 0 ]]; then
before_show_menu
fi
return 1
else
return 0
fi
}

check_install() {
check_status
if [[ $? == 2 ]]; then
echo ""
echo-e "${red} Please install the panel first${plain}"
if [[ $# == 0 ]]; then
before_show_menu
fi
return 1
else
return 0
fi
}

show_status() {
check_status
case $? in
0)
echo-e "Panel status: ${green} is running${plain}"
show_enable_status
;;
1)
echo-e "Panel status: ${yellow} not running${plain}"
show_enable_status
;;
2)
echo-e "Panel status: ${red}${plain} not installed"
esac
show_xray_status
}

show_enable_status() {
check_enabled
if [[ $? == 0 ]]; then
echo-e "Whether to boot from boot: ${green} is${plain}"
else
echo-e "Whether to boot from boot: ${red}no${plain}"
fi
}

check_xray_status() {
count=$(ps -ef | grep "xray-linux" | grep -v "grep" | wc -l)
if [[ count -ne 0 ]]; then
return 0
else
return 1
fi
}

show_xray_status() {
check_xray_status
if [[ $? == 0 ]]; then
echo-e "xray status: ${green} running${plain}"
else
echo-e "xray status: ${red} not running${plain}"
fi
}

show_usage() {
echo "How to use x-ui management script:"
echo "------------------------------------------"
echo "x-ui-display management menu (more functions)"
echo "x-ui start-start the x-ui panel"
echo "x-ui stop-stop the x-ui panel"
echo "x-ui restart-restart the x-ui panel"
echo "x-ui status-view x-ui status"
echo "x-ui enable-set x-ui to start automatically"
echo "x-ui disable-cancel x-ui to start automatically"
echo "x-ui log-view x-ui log"
echo "x-ui v2-ui-migrate the v2-ui account data of this machine to x-ui"
echo "x-ui update-update x-ui panel"
echo "x-ui install-install the x-ui panel"
echo "x-ui uninstall-uninstall the x-ui panel"
echo "------------------------------------------"
}

show_menu() {
echo -e "
${green}x-ui panel management script${plain}
${green}0. ${plain}exit script
————————————————
${green}1. ${plain} Install x-ui
${green}2. ${plain} update x-ui
${green}3. ${plain} uninstall x-ui
————————————————
${green}4. ${plain} Reset username and password
${green}5. ${plain} reset panel settings
${green}6. ${plain} Set the panel port
————————————————
${green}7. ${plain} Start x-ui
${green}8. ${plain} Stop x-ui
${green}9. ${plain} Restart x-ui
${green}10. ${plain} View x-ui status
${green}11. ${plain} View x-ui log
————————————————
${green}12. ${plain} Set x-ui to start automatically
${green}13. ${plain} Cancel x-ui to start automatically
————————————————
${green}14. ${plain}One-click installation of bbr (latest kernel)
"
show_status
echo&&read-p " Please enter and select [0-14]: "num

case "${num}" in
0) exit 0
;;
1) check_uninstall && install
;;
2) check_install && update
;;
3) check_install && uninstall
;;
4) check_install && reset_user
;;
5) check_install && reset_config
;;
6) check_install && set_port
;;
7) check_install && start
;;
8) check_install && stop
;;
9) check_install && restart
;;
10) check_install && status
;;
11) check_install && show_log
;;
12) check_install && enable
;;
13) check_install && disable
;;
14) install_bbr
;;
*) echo-e"${red} Please enter the correct number[0-14]${plain}"
;;
esac
}


if [[ $# > 0 ]]; then
case $1 in
"start") check_install 0 && start 0
;;
"stop") check_install 0 && stop 0
;;
"restart") check_install 0 && restart 0
;;
"status") check_install 0 && status 0
;;
"enable") check_install 0 && enable 0
;;
"disable") check_install 0 && disable 0
;;
"log") check_install 0 && show_log 0
;;
"v2-ui") check_install 0 && migrate_v2_ui 0
;;
"update") check_install 0 && update 0
;;
"install") check_uninstall 0 && install 0
;;
"uninstall") check_install 0 && uninstall 0
;;
*) show_usage
esac
else
show_menu
fi
