#!/bin/bash

#===========================================
# Script: TerminalScript
# Version: 1.0.1
# Author: imxiaoanag
# Uninstall Aliyun Script part by Babywbx
#===========================================

export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# 检查是否为管理员权限
[ $(id -u) != "0" ] && { echo "${Error}: 您需要管理员权限以运行该脚本"; exit 1; }

# 赋予变量定义
sh_ver="1.0.1"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

# UI helpers
print_line() {
    echo -e "${Green_font_prefix}============================================================${Font_color_suffix}"
}

press_enter() {
    read -p "按回车返回菜单..." _
}

confirm_action() {
    local msg="$1"
    read -r -p "${Tip}: ${msg} [y/N]: " yn
    case "$yn" in
        y|Y) return 0 ;;
        *) return 1 ;;
    esac
}

download_to_file() {
    local url="$1"
    local output="$2"

    if command -v wget >/dev/null 2>&1; then
        wget --no-check-certificate --timeout=15 --tries=2 -O "${output}" "${url}"
    elif command -v curl >/dev/null 2>&1; then
        curl -fL --connect-timeout 15 --retry 2 -o "${output}" "${url}"
    else
        echo -e "${Error}: 未检测到 wget 或 curl，请先安装其中一个。"
        return 1
    fi
}

download_to_stdout() {
    local url="$1"

    if command -v wget >/dev/null 2>&1; then
        wget --no-check-certificate -q --timeout=8 --tries=1 -O- "${url}"
    elif command -v curl >/dev/null 2>&1; then
        curl -fsSL --connect-timeout 8 --retry 1 "${url}"
    else
        echo -e "${Error}: 未检测到 wget 或 curl，请先安装其中一个。"
        return 1
    fi
}

# 检查系统
check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif grep -q -E -i "debian" /etc/issue 2>/dev/null || grep -q -E -i "debian" /proc/version; then
		release="debian"
		if grep -q -E -i "^10" /etc/debian_version 2>/dev/null; then
			deb_ver="10"
        elif grep -q -E -i "^9" /etc/debian_version 2>/dev/null; then
            deb_ver="9"
		fi
	elif grep -q -E -i "ubuntu" /etc/issue 2>/dev/null || grep -q -E -i "ubuntu" /proc/version; then
		release="ubuntu"
	elif grep -q -E -i "centos|red hat|redhat" /etc/issue 2>/dev/null || grep -q -E -i "centos|red hat|redhat" /proc/version; then
		release="centos"
	fi
}

# 更新脚本
Update_Shell(){
	echo -e "当前版本为 [ ${sh_ver} ]，开始检测最新版本..."
	if ! command -v wget >/dev/null 2>&1 && ! command -v curl >/dev/null 2>&1; then
		echo -e "${Error}: 未检测到 wget 或 curl，请先安装其中一个。"
		return 1
	fi

	sh_new_ver=$(download_to_stdout "https://raw.githubusercontent.com/matthewlu070111/TerminalScript/main/tscript.sh" 2>/dev/null | grep 'sh_ver="' | awk -F "=" '{print $NF}' | sed 's/\"//g' | head -1)
	if [[ -z "${sh_new_ver}" ]]; then
		echo -e "${Error}: 无法连接更新服务器或网络异常，请检查网络后重试。"
		return 1
	fi
	if [[ ${sh_new_ver} != ${sh_ver} ]]; then
		echo -e "发现新版本[ ${sh_new_ver} ]，是否更新？[Y/n]"
		read -p "(默认: y):" yn
		[[ -z "${yn}" ]] && yn="y"
		if [[ ${yn} == [Yy] ]]; then
			if download_to_file "https://raw.githubusercontent.com/matthewlu070111/TerminalScript/main/tscript.sh" "tscript.sh"; then
				chmod +x tscript.sh
				echo -e "脚本已更新为最新版本[ ${sh_new_ver} ] !"
			else
				echo -e "${Error}: 下载更新失败，请检查网络连接后重试。"
				return 1
			fi
		else
			echo && echo "	已取消..." && echo
		fi
	else
		echo -e "当前已是最新版本[ ${sh_new_ver} ] !"
	fi
}

# 卸载云盾
YunDun() {
    # 创建程序执行环境
    mkdir Uninstall_YunDun
    chmod 777 Uninstall_YunDun
    cd Uninstall_YunDun

    # 为CentOS 6/7补充运行环境
    if [[ "${release}" == "centos" ]]; then
        yum install redhat-lsb -y
    fi

    # 使用官方工具进行卸载
    download_to_file "http://update.aegis.aliyun.com/download/uninstall.sh" "uninstall.sh" && chmod +x uninstall.sh && ./uninstall.sh
    download_to_file "http://update.aegis.aliyun.com/download/quartz_uninstall.sh" "quartz_uninstall.sh" && chmod +x quartz_uninstall.sh && ./quartz_uninstall.sh
    
    # 杀死阿里云服务后台程序
    pkill aliyun-service
    rm -fr /etc/init.d/agentwatch /usr/sbin/aliyun-service
    rm -rf /usr/local/aegis*
    rm /usr/sbin/aliyun-service
    rm /lib/systemd/system/aliyun.service

    # 屏蔽阿里云云盾IP
    iptables -I INPUT -s 140.205.201.0/28 -j DROP
    iptables -I INPUT -s 140.205.201.16/29 -j DROP
    iptables -I INPUT -s 140.205.201.32/28 -j DROP
    iptables -I INPUT -s 140.205.225.192/29 -j DROP
    iptables -I INPUT -s 140.205.225.200/30 -j DROP
    iptables -I INPUT -s 140.205.225.184/29 -j DROP
    iptables -I INPUT -s 140.205.225.183/32 -j DROP
    iptables -I INPUT -s 140.205.225.206/32 -j DROP
    iptables -I INPUT -s 140.205.225.205/32 -j DROP
    iptables -I INPUT -s 140.205.225.195/32 -j DROP
    iptables -I INPUT -s 140.205.225.204/32 -j DROP
    iptables -I INPUT -s 106.11.222.0/23 -j DROP
    iptables -I INPUT -s 106.11.224.0/24 -j DROP
    iptables -I INPUT -s 106.11.228.0/22 -j DROP
    service iptables save
    
    # 删除阿里云云盾剩余文件，进行欺骗伪装
    rm -rf /etc/motd
    touch /etc/motd

    # 删除环境
    cd ..
    rm -rf Uninstall_YunDun
}

# 卸载云监控Go版本
go() {
    # 检测系统架构
    os=$(uname -m)
    if [[ "$os" == "x86_64" ]]; then
        ARCH=amd64
    else
        ARCH=386
    fi

    # 从系统服务中移除
    /usr/local/cloudmonitor/CmsGoAgent.linux-${ARCH} uninstall

    # 停止
    /usr/local/cloudmonitor/CmsGoAgent.linux-${ARCH} stop

    # 卸载
    /usr/local/cloudmonitor/CmsGoAgent.linux-${ARCH} stop && \
    /usr/local/cloudmonitor/CmsGoAgent.linux-${ARCH} uninstall && \
    rm -rf /usr/local/cloudmonitor
}

# 轻量云服务器
ali_light_server() {
    YunDun
    clear

    # 显示卸载完成
    echo -e "${Info}: 卸载已完成"
    press_enter
}

# 云服务器
ali_cloud_server() {
    YunDun
    go
    clear

    # 显示卸载完成
    echo -e "${Info}: 卸载已完成"
    press_enter
}

# 阿里云脚本卸载面板
uninstall_Aliyun() {
    while true; do
        clear
        print_line
        echo -e "  ${Green_background_prefix} 阿里云卸载面板 ${Font_color_suffix}  ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}"
        print_line
        echo -e "  ${Green_font_prefix}0.${Font_color_suffix} 返回上一页"
        echo -e "  ${Green_font_prefix}1.${Font_color_suffix} 轻量云服务器"
        echo -e "  ${Green_font_prefix}2.${Font_color_suffix} 云服务器"
        print_line
        echo
        read -p "请输入选项 [0-2]: " num
        case "$num" in
            0)
            return
            ;;
            1)
            if confirm_action "确认卸载轻量云服务器监控组件吗？"; then
                ali_light_server
            else
                echo -e "${Info}: 已取消操作。"
                sleep 1s
            fi
            ;;
            2)
            if confirm_action "确认卸载云服务器监控组件吗？"; then
                ali_cloud_server
            else
                echo -e "${Info}: 已取消操作。"
                sleep 1s
            fi
            ;;
            *)
            clear
            echo -e "${Error}: 请输入正确数字 [0-2]"
            sleep 2s
            ;;
        esac
    done
}

# Debian 10 更换源
optimize_debian10() {
    SOURCES_LIST="/etc/apt/sources.list"

    if [[ -f "$SOURCES_LIST" ]]; then
        cp -a "$SOURCES_LIST" "${SOURCES_LIST}.bak-$(date +%Y%m%d_%H%M%S)"
    fi

    cat > "$SOURCES_LIST" << 'EOF'
# deb http://deb.freexian.com/extended-lts buster main

deb http://deb.freexian.com/extended-lts buster main contrib non-free
# deb-src http://deb.freexian.com/extended-lts buster main contrib non-free
EOF

    KEY_URL="https://deb.freexian.com/extended-lts/archive-key.gpg"
    KEY_TMP="/tmp/elts-archive-key.gpg"
    KEY_DEST="/etc/apt/trusted.gpg.d/freexian-archive-extended-lts.gpg"
    mkdir -p "$(dirname "$KEY_DEST")"

    if ! download_to_file "$KEY_URL" "$KEY_TMP"; then
        echo -e "${Error}: 请您先联网再更新。"
        return 1
    fi

    if ! mv "$KEY_TMP" "$KEY_DEST"; then
        echo -e "${Error}: GPG Key 安装失败。"
        return 1
    fi

    chmod 644 "$KEY_DEST"
    apt update -y
    clear
    echo -e "${Info}: 更改成功！"
}

# Debian 9 更换源
optimize_debian9() {
    SOURCES_LIST="/etc/apt/sources.list"

    if [[ -f "$SOURCES_LIST" ]]; then
        cp -a "$SOURCES_LIST" "${SOURCES_LIST}.bak-$(date +%Y%m%d_%H%M%S)"
    fi

    cat > "$SOURCES_LIST" << 'EOF'
# deb http://deb.freexian.com/extended-lts stretch main

deb http://deb.freexian.com/extended-lts stretch main contrib non-free
# deb-src http://deb.freexian.com/extended-lts stretch main contrib non-free
EOF

    KEY_URL="https://deb.freexian.com/extended-lts/archive-key.gpg"
    KEY_TMP="/tmp/elts-archive-key.gpg"
    KEY_DEST="/etc/apt/trusted.gpg.d/freexian-archive-extended-lts.gpg"
    mkdir -p "$(dirname "$KEY_DEST")"

    if ! download_to_file "$KEY_URL" "$KEY_TMP"; then
        echo -e "${Error}: 请您先联网再更新。"
        return 1
    fi

    if ! mv "$KEY_TMP" "$KEY_DEST"; then
        echo -e "${Error}: GPG Key 安装失败。"
        return 1
    fi

    chmod 644 "$KEY_DEST"
    apt update -y
    clear
    echo -e "${Info}: 更改成功！"
}

version_ge() {
    local current="$1"
    local target="$2"
    [[ "$(printf '%s\n' "$target" "$current" | sort -V | head -n1)" == "$target" ]]
}

get_kernel_version() {
    uname -r | cut -d- -f1
}

is_bbr_enabled() {
    [[ "$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)" == "bbr" ]]
}

has_bbr_support() {
    sysctl net.ipv4.tcp_available_congestion_control 2>/dev/null | grep -qw bbr
}

write_bbr_config() {
    local conf legacy_conf
    legacy_conf="/etc/sysctl.conf"

    if [[ -f "${legacy_conf}" ]]; then
        conf="${legacy_conf}"
    else
        conf="/etc/sysctl.d/99-bbr.conf"
        mkdir -p /etc/sysctl.d
        touch "${conf}"
    fi

    if [[ -f "${legacy_conf}" ]]; then
        sed -i -E '/^[[:space:]]*#?[[:space:]]*net\.core\.default_qdisc[[:space:]]*=.*/d' "${legacy_conf}"
        sed -i -E '/^[[:space:]]*#?[[:space:]]*net\.ipv4\.tcp_congestion_control[[:space:]]*=.*/d' "${legacy_conf}"
    fi
    if [[ -f /etc/sysctl.d/99-bbr.conf ]]; then
        sed -i -E '/^[[:space:]]*#?[[:space:]]*net\.core\.default_qdisc[[:space:]]*=.*/d' /etc/sysctl.d/99-bbr.conf
        sed -i -E '/^[[:space:]]*#?[[:space:]]*net\.ipv4\.tcp_congestion_control[[:space:]]*=.*/d' /etc/sysctl.d/99-bbr.conf
    fi

    {
        echo "net.core.default_qdisc=fq"
        echo "net.ipv4.tcp_congestion_control=bbr"
    } >> "${conf}"
}

apply_bbr_now() {
    modprobe tcp_bbr >/dev/null 2>&1 || true
    sysctl -w net.core.default_qdisc=fq >/dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1 || true
}

upgrade_kernel_for_bbr() {
    case "${release}" in
        debian)
            local deb_arch kernel_pkg
            deb_arch="$(dpkg --print-architecture 2>/dev/null)"
            case "${deb_arch}" in
                amd64) kernel_pkg="linux-image-amd64 linux-headers-amd64" ;;
                arm64) kernel_pkg="linux-image-arm64 linux-headers-arm64" ;;
                *) 
                    echo -e "${Error}: 不支持的系统架构，无法升级内核以启用 BBR。"
                    return 1
                    ;;
            esac
            apt-get update -y && apt-get install -y ${kernel_pkg}
            ;;
        ubuntu)
            apt-get update -y && apt-get install -y linux-generic
            ;;
        centos)
            if command -v dnf >/dev/null 2>&1; then
                dnf -y upgrade kernel
            else
                yum -y update kernel
            fi
            ;;
        *)
            echo -e "${Error}: 不支持的发行版，无法升级内核以启用 BBR。"
            return 1
            ;;
    esac
}

enable_bbr_feature() {
    local kernel_ver
    kernel_ver="$(get_kernel_version)"

    clear

    if is_bbr_enabled; then
        echo -e "${Info}: BBR 已启用。"
        return 0
    fi

    if version_ge "${kernel_ver}" "4.9"; then
        write_bbr_config
        apply_bbr_now
    else
        echo -e "${Tip}: Linux 内核版本过低。当前版本为 ${kernel_ver}，需要升级到 4.9 及以上以启用 BBR。"
        if ! confirm_action "是否升级 Linux 内核以启用 BBR？"; then
            echo -e "${Info}: 已取消操作。"
            return 0
        fi

        if ! upgrade_kernel_for_bbr; then
            echo -e "${Error}: 内核升级失败，请重试。"
            return 1
        fi

        write_bbr_config
        if has_bbr_support; then
            apply_bbr_now
        fi
    fi

    if is_bbr_enabled; then
        echo -e "${Info}: BBR 已成功启用。"
    else
        echo -e "${Tip}: BBR 启用失败，可能需要重启系统后生效。"
    fi
}

# 开始菜单
start_menu() {
    while true; do
        clear
        print_line
        echo -e "  ${Green_background_prefix} TerminalScript 控制面板 ${Font_color_suffix}  By imxiaoanag ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}"
        print_line
        echo -e "  ${Green_font_prefix}0.${Font_color_suffix} 退出脚本"
        echo -e ""
        echo -e "  ${Green_font_prefix}1.${Font_color_suffix} 卸载阿里云中国监控"
        echo -e "  ${Green_font_prefix}2.${Font_color_suffix} 旧版 Debian 更换 APT 源"
        echo -e "  ${Green_font_prefix}3.${Font_color_suffix} 自动启用 BBR 加速"
        echo -e ""
        echo -e "  ${Green_font_prefix}9.${Font_color_suffix} 升级脚本"
        print_line
        echo
        read -p "请输入选项 [0-9]: " num
        case "$num" in
            0)
            exit 0
            ;;
            1)
            uninstall_Aliyun
            ;;
            2)
            if [[ "${deb_ver}" == "10" ]]; then
                optimize_debian10
            elif [[ "${deb_ver}" == "9" ]]; then
                optimize_debian9
            else
                echo -e "${Info}: 仅支持 Debian 9 与 Debian 10"
            fi
            press_enter
            ;;
            3)
            enable_bbr_feature
            press_enter
            ;;
            9)
            Update_Shell
            press_enter
            ;;
            *)
            clear
            echo -e "${Error}: 请输入正确数字 [0-9]"
            press_enter
            ;;
        esac
    done
}

# 运行检查系统
check_sys

# 运行开始菜单
start_menu