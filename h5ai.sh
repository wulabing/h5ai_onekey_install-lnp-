#!/bin/bash

# ====================================================
#	System Request:Debian 8+/Ubuntu 16.04+
#	Author:	wulabing
#	Dscription: LNP-H5AI-onekey (only)
#	Version: 1.0
#	Blog: https://www.wulabing.com
# ====================================================

#fonts color
Green="\033[32m" 
Red="\033[31m" 
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
Font="\033[0m"

#notification information
Info="${Green}[Info]${Font}"
OK="${Green}[OK]${Font}"
Error="${Red}[Error]${Font}"

#folder
nginx_conf_dir="/etc/nginx/conf.d"
h5ai_zip="h5ai-0.29.0.zip"
h5ai_download_http="https://release.larsjung.de/h5ai/${h5ai_zip}"


source /etc/os-release &>/dev/null
# 系统检测、仅支持 Debian8+ 和 Ubuntu16.04+
check_system(){
    if [[ "${ID}" == "debian" && ${VERSION_ID} -ge 8 ]];then
        echo -e "${OK} ${GreenBG} 当前系统为 Debian ${VERSION_ID} ${Font} "
    elif [[ "${ID}" == "ubuntu" && `echo "${VERSION_ID}" | cut -d '.' -f1` -ge 16 ]];then
        echo -e "${OK} ${GreenBG} 当前系统为 Ubuntu ${VERSION_ID} ${Font} "
    else
        echo -e "${Error} ${RedBG} 当前系统为不在支持的系统列表内，安装中断 ${Font} "
        exit 1
    fi
}
# 判定是否为root用户
is_root(){
    if [ `id -u` == 0 ]
        then echo -e "${OK} ${GreenBG} 当前用户是root用户，进入安装流程 ${Font} "
        sleep 1
    else
        echo -e "${Error} ${RedBG} 当前用户不是root用户，请切换到root用户后重新执行脚本 ${Font}" 
        exit 1
    fi
}
debian_source(){
    # 添加源
    echo "deb http://packages.dotdeb.org jessie all" | tee --append /etc/apt/sources.list
    echo "deb-src http://packages.dotdeb.org jessie all" | tee --append /etc/apt/sources.list
    # 添加key
    wget --no-check-certificate https://www.dotdeb.org/dotdeb.gpg
    if [[ -f dotdeb.gpg ]];then
        apt-key add dotdeb.gpg
        if [[ $? -eq 0 ]];then
            echo -e "${OK} ${GreenBG} 导入 GPG 秘钥成功 ${Font}"
            sleep 1
        else
            echo -e "${Error} ${RedBG} 导入 GPG 秘钥失败 ${Font}"
            exit 1
        fi
    else
        echo -e "${Error} ${RedBG} 下载 GPG 秘钥失败 ${Font}"
        exit 1
    fi
    # 源更新
    apt-get update 
}
basic_dependency(){
    apt update
    apt install wget unzip -y     
}
nginx_install(){
    apt install nginx -y
    if [[ $? -eq 0 ]];then
        echo -e "${OK} ${GreenBG} nginx 安装成功 ${Font}"
        sleep 1
    else
        debian_source
        apt install nginx -y
        if [[ $? -eq 0 ]];then
            echo -e "${OK} ${GreenBG} nginx 安装成功 ${Font}"
            sleep 1
        else
            echo -e "${Error} ${RedBG} nginx 安装失败 ${Font}"
            exit 1
        fi
    fi   
}
php7_install(){
    apt install php7.0-cgi php7.0-fpm php7.0-curl php7.0-gd -y
    if [[ $? -eq 0 ]];then
        echo -e "${OK} ${GreenBG} php7 安装成功 ${Font}"
        sleep 1
    else
        debian_source
        apt install php7.0-cgi php7.0-fpm php7.0-curl php7.0-gd -y
        if [[ $? -eq 0 ]];then
            echo -e "${OK} ${GreenBG} php7 安装成功 ${Font}"
            sleep 1
        else
            echo -e "${Error} ${RedBG} php7 安装失败 ${Font}"
            exit 1
        fi
    fi   
}
nginx_conf_add(){
    cat > ${nginx_conf_dir}/h5ai.conf <<EOF
server {
    listen 80;

    server_name ${domain};
    root /home/wwwroot/${domain};
    index index.html /_h5ai/public/index.php;        
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php7.0-fpm.sock;
    }
}
EOF
    if [[ $? -eq 0 ]];then
        echo -e "${OK} ${GreenBG} nginx 配置导入成功 ${Font}"
        sleep 1
    else
        echo -e "${Error} ${RedBG} nginx 配置导入失败 ${Font}"
        exit 1
    fi
    
}
h5ai_install(){
    mkdir -p /home/wwwroot/${domain} && cd /home/wwwroot/${domain}&& wget ${h5ai_download_http} && unzip ${h5ai_zip}
    if [[ $? -eq 0 ]];then
        echo -e "${OK} ${GreenBG} h5ai 下载成功 ${Font}"
        sleep 1
    else
        echo -e "${Error} ${RedBG} h5ai 下载失败 ${Font}"
        exit 1
    fi
}
h5ai_dependency(){
    apt install libav-tools -y
    if [[ $? -eq 0 ]];then
        echo -e "${OK} ${GreenBG} 成功添加 Movie thumbs 支持 ${Font}"
        sleep 1
    else
        echo -e "${Error} ${RedBG} 未添加 Movie thumbs 支持 ${Font}"
    fi
    apt install aptitude -y
    aptitude install imagemagick -y
    if [[ $? -eq 0 ]];then
        echo -e "${OK} ${GreenBG} 成功添加 PDF thumbs 支持 ${Font}"
        sleep 1
    else
        echo -e "${Error} ${RedBG} 未添加 PDF thumbs 支持 ${Font}"
    fi
    apt install zip -y
    if [[ $? -eq 0 ]];then
        echo -e "${OK} ${GreenBG} 成功添加 zip 支持 ${Font}"
        sleep 1
    else
        echo -e "${Error} ${RedBG} 未添加 zip 支持 ${Font}"
    fi

    chmod 666 /home/wwwroot/${domain}/_h5ai/private/cache
    echo -e "${OK} ${GreenBG} 成功添加 Public Cache directory 支持 ${Font}"
    sleep 1
    chmod 666 /home/wwwroot/${domain}/_h5ai/public/cache
    echo -e "${OK} ${GreenBG} 成功添加 Private Cache directory 支持 ${Font}"
    sleep 1
}
user_input(){
    read -p "请输入域名信息：" domain
}
main(){
    check_system
    is_root
    user_input
    basic_dependency
    nginx_install
    php7_install
    h5ai_install
    h5ai_dependency
    nginx_conf_add
    systemctl restart nginx
    systemctl restart php7.0-fpm
    echo -e "${OK} ${GreenBG} h5ai 安装成功 ${Font}"
}

main
