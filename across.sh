#!/bin/bash
date_setting(){
	
	cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	date

}

download_bbr(){
	wget -N --no-check-certificate "https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh" && chmod +x tcp.sh && ./tcp.sh
}

install_docker(){
	apt-get install curl -y
	docker version > /dev/null || curl -fsSL get.docker.com | bash
	service docker restart

}
start_menu(){
	clear
	echo && echo -e "Across Script
	——————————————————————————————————————————————
	1. 修改时区 change date
	2. 安装bbr脚本
	3. 安装docker
	4. Exit
	——————————————————————————————————————————————"

echo
read -p " 请输入数字 [0-11]:" num
case "$num" in 
	1)
	date_setting;;
	2)
	download_bbr;;
	3)
	install_docker;;
	4)
	exit 1;;
esac
	
}

start_menu

