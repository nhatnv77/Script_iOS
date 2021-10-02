#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red} error: ${plain} must use the root user to run this script!\n" && exit 1

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
    echo -e "The system version of ${red} is not detected, please contact the script author! ${plain}\n" && exit 1
fi

arch=$(arch)

if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
  arch="amd64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
  arch="arm64"
else
  arch="amd64"
  echo -e "${red} failed to detect architecture, use default architecture: ${arch}${plain}"
fi

echo "architecture: ${arch}"

if [$(getconf WORD_BIT) != '32'] && [$(getconf LONG_BIT) != '64']; then
    echo "This software does not support 32-bit systems (x86), please use 64-bit systems (x86_64), if the detection is wrong, please contact the author"
    exit -1
fi

os_version=""

# os version
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]''/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+''/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        echo -e "${red} Please use CentOS 7 or higher version system! ${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}Please use Ubuntu 16 or higher version system! ${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red} Please use Debian 8 or higher version system! ${plain}\n" && exit 1
    fi
fi

install_base() {
    if [[ x"${release}" == x"centos" ]]; then
        yum install wget curl tar -y
    else
        apt install wget curl tar -y
    fi
}

install_x-ui() {
    systemctl stop x-ui
    cd /usr/local/

    if [$# == 0] ;then
        last_version=$(curl -Ls "https://api.github.com/repos/vaxilu/x-ui/releases/latest" | grep'"tag_name":' | sed -E's/.*"([ ^"]+)".*/\1/')
        if [[! -n "$last_version" ]]; then
            echo -e "${red} failed to detect the x-ui version, which may be beyond the Github API limit, please try again later, or manually specify the x-ui version to install ${plain}"
            exit 1
        fi
        echo -e "The latest version of x-ui is detected: ${last_version}, start installation"
        wget -N --no-check-certificate -O /usr/local/x-ui-linux-${arch}.tar.gz https://github.com/vaxilu/x-ui/releases/download/$ {last_version}/x-ui-linux-${arch}.tar.gz
        if [[ $? -ne 0 ]]; then
            echo -e "${red} failed to download x-ui, please make sure your server can download Github files ${plain}"
            exit 1
        fi
    else
        last_version=$1
        url="https://github.com/vaxilu/x-ui/releases/download/${last_version}/x-ui-linux-${arch}.tar.gz"
        echo -e "Start to install x-ui v$1"
        wget -N --no-check-certificate -O /usr/local/x-ui-linux-${arch}.tar.gz ${url}
        if [[ $? -ne 0 ]]; then
            echo -e "${red} download x-ui v$1 failed, please make sure this version exists ${plain}"
            exit 1
        fi
    fi

    if [[ -e /usr/local/x-ui/ ]]; then
        rm /usr/local/x-ui/ -rf
    fi

    tar zxvf x-ui-linux-${arch}.tar.gz
    rm x-ui-linux-${arch}.tar.gz -f
    cd x-ui
    chmod +x x-ui bin/xray-linux-${arch}
    cp -f x-ui.service /etc/systemd/system/
    wget --no-check-certificate -O /usr/bin/x-ui https://raw.githubusercontent.com/vaxilu/x-ui/main/x-ui.sh
    chmod +x /usr/bin/x-ui
    systemctl daemon-reload
    systemctl enable x-ui
    systemctl start x-ui
    echo -e "${green}x-ui v${last_version}${plain} The installation is complete, the panel has been activated,"
    echo -e ""
    echo -e "If it is a new installation, the default web port is ${green}54321${plain}, and the default username and password are both ${green}admin${plain}"
    echo -e "Please make sure that this port is not occupied by other programs, ${yellow} and make sure that port 54321 has been released ${plain}"
# echo -e "If you want to modify 54321 to another port, enter the x-ui command to modify it, and also make sure that the port you modify is also allowed"
    echo -e ""
    echo -e "If it is to update the panel, access the panel as you did before"
    echo -e ""
    echo -e "x-ui management script usage: "
    echo -e "---------------------------------------------- "
    echo -e "x-ui-show management menu (more functions)"
    echo -e "x-ui start-start x-ui panel"
    echo -e "x-ui stop-stop x-ui panel"
    echo -e "x-ui restart-restart x-ui panel"
    echo -e "x-ui status-view x-ui status"
    echo -e "x-ui enable-set x-ui to start automatically after booting"
    echo -e "x-ui disable-cancel x-ui boot from start"
    echo -e "x-ui log-view x-ui log"
    echo -e "x-ui v2-ui-Migrate the v2-ui account data of this machine to x-ui"
    echo -e "x-ui update-update x-ui panel"
    echo -e "x-ui install-install x-ui panel"
    echo -e "x-ui uninstall-uninstall x-ui panel"
    echo -e "---------------------------------------------- "
}

echo -e "${green} start to install ${plain}"
install_base
install_x-ui $1
