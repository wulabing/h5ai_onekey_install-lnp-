#!/bin/bash

# ====================================================
#	System Request:Debian 8+/Ubuntu 16.04+
#	Author:	wulabing
#	Dscription: LNP-H5AI-onekey (only)
#	Version: 2.0
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
    apt install wget unzip net-tools bc -y     
}
nginx_install(){
        debian_source
        apt install nginx -y
        if [[ $? -eq 0 ]];then
            echo -e "${OK} ${GreenBG} nginx 安装成功 ${Font}"
            sleep 1
        else
            echo -e "${Error} ${RedBG} nginx 安装失败 ${Font}"
            exit 1
        fi   
}
php7_install(){
        apt install php7.0-cgi php7.0-fpm php7.0-curl php7.0-gd -y
        if [[ $? -eq 0 ]];then
            echo -e "${OK} ${GreenBG} php7 安装成功 ${Font}"
            sleep 1
        else
            echo -e "${Error} ${RedBG} php7 安装失败 ${Font}"
            exit 1
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
nginx_conf_ssl_add(){
    cat > ${nginx_conf_dir}/h5ai.conf <<EOF
server
    {
        listen 443 ssl http2;
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
        server_name ${domain};
        root /home/wwwroot/${domain};
        index index.html /_h5ai/public/index.php;
        ssl on;
        ssl_certificate /home/wwwroot/ssl/h5ai.crt;
        ssl_certificate_key /home/wwwroot/ssl/h5ai.key;
        ssl_session_timeout 5m;
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        ssl_prefer_server_ciphers on;
        ssl_ciphers "EECDH+CHACHA20:EECDH+CHACHA20-draft:EECDH+AES128:RSA+AES128:EECDH+AES256:RSA+AES256:EECDH+3DES:RSA+3DES:!MD5";
        ssl_session_cache builtin:1000 shared:SSL:10m;
        location ~ \.php$ {
            include snippets/fastcgi-php.conf;
            fastcgi_pass unix:/run/php/php7.0-fpm.sock;
        }
        location ~ .*\.(gif|jpg|jpeg|png|bmp|swf)$
        {
            expires      30d;
        }

        location ~ .*\.(js|css)?$
        {
            expires      12h;
        }
        access_log off;
    }
server
    {
        listen 80;
        server_name ${domain};
        rewrite ^(.*) https://${domain}\$1 permanent;
    }
EOF
    if [[ $? -eq 0 ]];then
        echo -e "${OK} ${GreenBG} nginx SSL 配置导入成功 ${Font}"
        sleep 1
    else
        echo -e "${Error} ${RedBG} nginx SSL 配置导入失败 ${Font}"
        exit 1
    fi
}
ssl_install(){
    apt install socat netcat -y
    if [[ $? -eq 0 ]];then
        echo -e "${OK} ${GreenBG} SSL 证书生成脚本依赖安装成功 ${Font}"
        sleep 2
    else
        echo -e "${Error} ${RedBG} SSL 证书生成脚本依赖安装失败 ${Font}"
        exit 6
    fi

    curl  https://get.acme.sh | sh

    if [[ $? -eq 0 ]];then
        echo -e "${OK} ${GreenBG} SSL 证书生成脚本安装成功 ${Font}"
        sleep 2
    else
        echo -e "${Error} ${RedBG} SSL 证书生成脚本安装失败，请检查相关依赖是否正常安装 ${Font}"
        exit 7
    fi

}
acme(){
    mkdir -p /home/wwwroot/ssl
    ~/.acme.sh/acme.sh --issue -d ${domain} --standalone -k ec-256 --force
    if [[ $? -eq 0 ]];then
        echo -e "${OK} ${GreenBG} SSL 证书生成成功 ${Font}"
        sleep 2
        ~/.acme.sh/acme.sh --installcert -d ${domain} --fullchainpath /home/wwwroot/ssl/h5ai.crt --keypath /home/wwwroot/ssl/h5ai.key --ecc
        if [[ $? -eq 0 ]];then
        echo -e "${OK} ${GreenBG} 证书配置成功 ${Font}"
        sleep 2
        else
        echo -e "${Error} ${RedBG} 证书配置失败 ${Font}"
        fi
    else
        echo -e "${Error} ${RedBG} SSL 证书生成失败 ${Font}"
        exit 1
    fi
}
port_exist_check(){
    if [[ 0 -eq `netstat -tlpn | grep "$1"| wc -l` ]];then
        echo -e "${OK} ${GreenBG} $1 端口未被占用 ${Font}"
        sleep 1
    else
        echo -e "${Error} ${RedBG} $1 端口被占用，请检查占用进程 结束后重新运行脚本 ${Font}"
        netstat -tlpn | grep "$1"
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
domain_check(){
    stty erase '^H' && read -p "请输入你的域名信息(eg:www.wulabing.com):" domain
    ## ifconfig
    ## stty erase '^H' && read -p "请输入公网 IP 所在网卡名称(default:eth0):" broadcast
    ## [[ -z ${broadcast} ]] && broadcast="eth0"
    domain_ip=`ping ${domain} -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`
    local_ip=`ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6 | awk '{print $2}' | tr -d "addr:"`
    echo -e "域名dns解析IP：${domain_ip}"
    echo -e "本机IP: ${local_ip}"
    sleep 2
    if [[ $(echo ${local_ip}|tr '.' '+'|bc) -eq $(echo ${domain_ip}|tr '.' '+'|bc) ]];then
        echo -e "${OK} ${GreenBG} 域名dns解析IP  与 本机IP 匹配 ${Font}"
        sleep 2
    else
        echo -e "${Error} ${RedBG} 域名dns解析IP 与 本机IP 不匹配 是否继续安装？（y/n）${Font}" && read install
        case $install in
        [yY][eE][sS]|[yY])
            echo -e "${GreenBG} 继续安装 ${Font}" 
            sleep 2
            ;;
        *)
            echo -e "${RedBG} 安装终止 ${Font}" 
            exit 2
            ;;
        esac
    fi
}
standard(){
    basic_dependency
    domain_check
    nginx_install
    php7_install
    h5ai_install
    h5ai_dependency
    nginx_conf_add
}
ssl(){

    systemctl stop nginx
    systemctl stop php7.0-fpm

    port_exist_check 80
    port_exist_check 443

    ssl_install
    acme
    nginx_conf_ssl_add

    systemctl start nginx
    systemctl start php7.0-fpm
}
main(){
    check_system
    is_root
	sleep 2
	echo -e "${Red} 请选择安装内容 ${Font}"
	echo -e "1. h5ai"
	echo -e "2. SSL"
	echo -e "3. h5ai+SSL"
	read -p "input:" number
	case ${number} in
		1)
            standard
            echo -e "${OK} ${GreenBG} h5ai 安装成功 ${Font}"
			;;
		2)
            domain_check
			ssl
			;;
		3)
            standard
            ssl
            echo -e "${OK} ${GreenBG} h5ai + SSL 安装成功 ${Font}"
			;;
		*)
			echo -e "${Error} ${RedBG} 请输入正确的序号 ${Font}"
			exit 1
			;;
	esac
   
}

main
