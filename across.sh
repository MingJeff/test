#!/bin/bash
#下载地址：wget -N --no-check-certificate "https://raw.github.com/MingJeff/test/Across/across.sh" && chmod +x across.sh && ./across.sh



# 手动更新脚本
manual_update_scriptttt() {
    echo "正在手动更新脚本..."
    wget --no-check-certificate "https://raw.githubusercontent.com/MingJeff/test/Across/across.sh?ts=$(date +%s)" -O "$0"
    chmod +x "$0"
    echo "更新完成，正在重新启动脚本..."
    exec "$0"
}
manual_update_script() {
    echo "正在手动更新脚本..."
    tmpfile=$(mktemp)
    curl -fsSL "https://raw.githubusercontent.com/MingJeff/test/Across/across.sh?ts=$(date +%s)" -o "$tmpfile"
    if [ $? -ne 0 ]; then
        echo "❌ 下载失败，保留旧版本脚本。"
        rm -f "$tmpfile"
        return
    fi
    chmod +x "$tmpfile"
    echo "✅ 脚本已更新，将重新启动..."
    exec "$tmpfile"
}



# 自动更新检测：超过7天未运行，询问是否更新
check_and_update_script() {
    SCRIPT_PATH="$0"
    LAST_RUN_FILE="/tmp/.across_last_run"
    REMOTE_URL="https://raw.github.com/MingJeff/test/Across/across.sh"

    NOW=$(date +%s)

    if [ ! -f "$LAST_RUN_FILE" ]; then
        echo "$NOW" > "$LAST_RUN_FILE"
        return
    fi

    LAST=$(cat "$LAST_RUN_FILE")
    DIFF=$(( (NOW - LAST) / 86400 ))

    if [ $DIFF -ge 7 ]; then
        echo "检测到本脚本已 $DIFF 天未更新。是否现在更新？"
        echo "1. 更新"
        echo "2. 不更新"
        read -p "请输入选项 [1/2]: " opt
        if [ "$opt" = "1" ]; then
            echo "开始更新..."
            wget -N --no-check-certificate "$REMOTE_URL" -O "$SCRIPT_PATH"
            chmod +x "$SCRIPT_PATH"
            echo "$NOW" > "$LAST_RUN_FILE"
            echo "更新完成，重新运行脚本..."
            exec "$SCRIPT_PATH"
        else
            echo "跳过更新。"
        fi
    fi

    echo "$NOW" > "$LAST_RUN_FILE"
}

check_and_update_script



# 显示 XrayR-script 当前 NodeID 和容器状态
show_nodeid() {
    echo "当前运行的 Docker 容器列表："
    docker container ls
    echo
    if docker container ls --format '{{.Image}}' | grep -q mikumiku1/xrayr; then
        config_path="/root/XrayR-script/config/config.yml"
        if [ -f "$config_path" ]; then
            nodeid=$(grep 'NodeID:' "$config_path" | awk '{print $2}')
            echo "当前运行中的 XrayR-script 配置 NodeID: $nodeid"
        else
            echo "未找到 config.yml 配置文件。"
        fi
    else
        echo "未检测到 XrayR-script 容器运行。"
    fi
    read -p "按回车键继续..."
}

# 设置 root 密码
set_root_password(){
    read -s -p "请输入你想设置的 root 密码: " rootpasswd
    echo
    read -s -p "请再次输入密码确认: " rootpasswd2
    echo

    if [ "$rootpasswd" != "$rootpasswd2" ]; then
        echo "两次输入的密码不一致，退出脚本。"
        exit 1
    fi

    echo "root:$rootpasswd" | chpasswd
    echo "已成功设置 root 密码。"
    echo
    echo "请妥善保存您的密码，以下是您刚刚设置的 root 密码："
    echo
    echo "root 密码：$rootpasswd"
    echo
}

# 添加 SSH 端口 22
add_ssh_port_22(){
    SSHD_CONFIG="/etc/ssh/sshd_config"
    cp $SSHD_CONFIG ${SSHD_CONFIG}.bak
    sed -i 's/^#\?\s*PermitRootLogin.*/PermitRootLogin yes/' $SSHD_CONFIG
    sed -i 's/^#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/' $SSHD_CONFIG
    if ! grep -q "^Port 22" $SSHD_CONFIG; then
        echo "Port 22" >> $SSHD_CONFIG
        echo "已添加 Port 22"
    else
        echo "Port 22 已存在，未重复添加。"
    fi

    if command -v systemctl &> /dev/null; then
        systemctl restart ssh || systemctl restart sshd
    else
        service ssh restart || service sshd restart
    fi

    echo "SSH 服务已重启完成，可使用原端口或 22 登录。"
}

# 一键删除所有 Docker 容器
remove_all_docker_containers() {
    docker rm -f $(docker ps -aq) && echo "已删除全部 Docker 容器"
    read -p "按回车键继续..."
}

# -------------------------- 以上更新于2025/05/28 --------------------------

#修改时区 Change Date
date_setting(){
    
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    date

}

#安装BBR
download_bbr(){
    wget --no-check-certificate -O tcp.sh https://raw.githubusercontent.com/Mufeiss/Linux-NetSpeed/master/tcp.sh && chmod +x tcp.sh && ./tcp.sh
}


# 同时安装 Docker 和 Docker Compose
install_docker() {
    OS_VERSION=$(lsb_release -rs)

    if [[ "$OS_VERSION" == "16.04" ]]; then
        echo "⚠️ 检测到 Ubuntu 16.04，使用兼容模式安装 Docker + Compose"

        apt update -y
        apt install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common

        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

        add-apt-repository \
           "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
           xenial \
           stable"

        apt update -y

        apt install -y docker-ce=5:18.09.7~3-0~ubuntu-xenial \
                       docker-ce-cli=5:18.09.7~3-0~ubuntu-xenial \
                       containerd.io

        service docker start || systemctl start docker

        COMPOSE_VERSION="1.29.2"
        curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
            -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose

        echo ""
        echo "✅ Ubuntu 16.04 安装完成，Docker 与 docker-compose 已就绪。"

    else
        echo "🟢 检测到系统版本为 $OS_VERSION，使用标准流程安装 Docker + Compose"

        apt update -y
        apt install -y ca-certificates curl gnupg lsb-release apt-transport-https

        mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

        echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
        https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

        apt update -y
        apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

        systemctl enable docker
        systemctl start docker

        echo ""
        echo "✅ Docker 和 docker compose 安装完成"
    fi
}




#初次对接数据库
docker_deploy(){
    read -p "Please assign the node ID 请输入节点ID:" node_idof
    echo $node_idof " is the new node ID"
    docker run -d --name=ssrmu -e NODE_ID=$node_idof -e API_INTERFACE=glzjinmod -e MYSQL_HOST=35.185.164.17 -e MYSQL_USER=sspanel -e MYSQL_DB=sspanel -e MYSQL_PASS=60731240yym --network=host --log-opt max-size=50m --log-opt max-file=3 --restart=always fanvinga/docker-ssrmu && echo && echo "ssrmu deployed successfully" 
}
    
#删除docker_ssrmu
remove_ssrmu(){
    docker rm -f ssrmu && echo "ssrmu removed sucessfully"
}

#删除docker_v2ray
remove_v2ray(){
docker rm -f v2rayagent_v2ray_1 && echo "v2rayagent_v2ray_1 removed sucessfully"
}

#添加新的cron管理docker
edit_new_cron(){

    read -p "Please assign the node ID 请输入节点ID:" node_idof
    echo $node_idof " is the new node ID"
    (crontab -l ; echo "0 */6 * * * docker rm -f ssrmu && docker run -d --name=ssrmu -e NODE_ID=$node_idof -e API_INTERFACE=glzjinmod -e MYSQL_HOST=35.185.164.17 -e MYSQL_USER=sspanel -e MYSQL_DB=sspanel -e MYSQL_PASS=60731240yym --network=host --log-opt max-size=50m --log-opt max-file=3 --restart=always fanvinga/docker-ssrmu" ) | crontab - | echo "A new crontab with Node ID $node_idof installed sucessfully" 

}


one_click_install_for_across(){
    read -p "Please assign the node ID 请输入节点ID:" node_idof
    echo $node_idof " is the new node ID"
    docker run -d --name=ssrmu -e NODE_ID=$node_idof -e API_INTERFACE=glzjinmod -e MYSQL_HOST=35.185.164.17 -e MYSQL_USER=sspanel -e MYSQL_DB=sspanel -e MYSQL_PASS=60731240yym --network=host --log-opt max-size=50m --log-opt max-file=3 --restart=always fanvinga/docker-ssrmu && echo && echo "ssrmu deployed successfully" 
    (crontab -l ; echo "0 */6 * * * docker rm -f ssrmu && docker run -d --name=ssrmu -e NODE_ID=$node_idof -e API_INTERFACE=glzjinmod -e MYSQL_HOST=35.185.164.17 -e MYSQL_USER=sspanel -e MYSQL_DB=sspanel -e MYSQL_PASS=60731240yym --network=host --log-opt max-size=50m --log-opt max-file=3 --restart=always fanvinga/docker-ssrmu" ) | crontab - | echo "A new crontab with Node ID $node_idof installed sucessfully"

}


one_click_uninstall_for_across(){
    $(remove_ssrmu)
    crontab -r | echo "crontab clear now"
    echo "remove ssrmu and crontab clear sucessfully"
}


v2ray_sspanel_install(){
   if [[ -d /root/v2ray-agent ]]
	then 
		cd v2ray-agent 
	else
	    mkdir v2ray-agent && cd v2ray-agent && curl https://raw.githubusercontent.com/hulisang/v2ray-sspanel-v3-mod_Uim-plugin/master/install.sh -o install.sh && chmod +x install.sh  
	fi
   
    read -p "Please assign the node ID 请输入节点ID:" node_idof 
   
    printf '1\n3\nhttps://goacross2020.com\nacrossthegreatwall\n6\n'$node_idof'\n2333\n0' |./install.sh 2>/dev/null && echo "A new v2ray-agent has been installed with NodeID $node_idof"
}


	



download_dockercompose(){
	mkdir proxy
	cd proxy
	wget -N --no-check-certificate "https://raw.github.com/MingJeff/test/Across/docker-compose.yaml" && chmod 777 docker-compose.yaml
}
	
download_XrayR(){
	cd ~/proxy
	git clone https://github.com/MingJeff/XrayR
	
}

edit_configyml(){
	cd ~/proxy/XrayR/config
	wget -N --no-check-certificate "https://raw.github.com/MingJeff/test/Across/config.yml" && chmod 777 config.yml
	read -p "Please assign the node ID 请输入节点ID:" node_idof 
	sed -i 's/10086/'$node_idof'/g' config.yml
}

start_dockercompose(){
	cd ~/proxy
	docker rm -f v2rayagent_v2ray_1
	docker-compose up -d
}

one_click_install_XrayR(){
	$(download_dockercompose)
	$(download_XrayR)
	$(edit_configyml)
	$(start_dockercompose)

}


X2rayR_script_install(){
    if ! command -v git &> /dev/null; then
        echo "未检测到 git，正在安装..."
        apt-get update && apt-get install git -y
    fi

    git clone https://github.com/Miku-Miku-Miku-Miku/XrayR-script
    cd XrayR-script/config

    wget -N --no-check-certificate "https://raw.github.com/MingJeff/test/Across/config.yml" && chmod 777 config.yml

    read -p "Please assign the node ID 请输入节点ID:" node_idof 
    sed -i 's/10086/'$node_idof'/g' config.yml

    cd ..
    docker-compose up -d
}

# 添加 SSH 公钥（Across2025_key）
add_ssh_pubkey() {
    echo "🔐 正在配置 SSH 公钥登录..."

    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    touch ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys

    PUBKEY='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDwCS28O1hFZ5FWA1YHkBbvULBLCU0diHh5udmEecJ7Y/9mrxZ8hRoOX239L//qw/UzvevEQOMKz129R0ykhyLCM6qQ+zx+7+fGx6EYmIBNhw2aI4aFhda/OqDR1i7eQMpj4JrweE7Eh8tqXpjgPggL3k9KsX3B/0D2pnOGIF/lzEoB3SdueuAGQWlAHBkTnafbV7y0deBa63xpIo5Pvzn4ZhjXqAuwBE7ocGFrEfePOTgvubRqV3+9NDPKu9Nvgynt5etd9dNYcfjYw2UxQuCclpR9L7zqYE7knVaHdJMDxsPkLlCMBxWpVmZicoS5yi7KVDboTbCBcdXcbEsZOhkW4reCZgyjqYWOhS8nAQY+jS3DcRKM/kfQXo2xhMYAX85eMjhlwXnj68OiKJBsQOKfGH6YEqE+rstBkZcCur/hu7KcrLWrLz9Cj4n+HWGEg+uD0MuijoJJelFT218Y+7bFxnDHx13HjxBZkIM1qarRfemZA8ZBMAhQn6xcVr4C0ZDd0UtgGV2upvEhtzBPgzNoUMROY5aPWL0ZjTZWQuzWHuLN+ZKHiKgenbrk3HOeinWSM0aI2kq1D8fyPaT6YQtMhcqeFBpeSyiMtK9Pj8Xl3zt7evxht34Z2qrhukZTJBrhQrspms046EQ9djX/7krn1lsCzz5EltMayzXxqwZ6iw== Across2025_key'

    if grep -qxF "$PUBKEY" ~/.ssh/authorized_keys; then
        echo "✅ 公钥已存在，无需重复添加。"
    else
        echo "$PUBKEY" >> ~/.ssh/authorized_keys
        echo "✅ 公钥已成功添加至 ~/.ssh/authorized_keys"
    fi

    echo
    read -p "按回车键继续..."
}

# 判断是否只允许密钥登录
only_allow_ssh_key_login() {
    echo "🔍 正在检查是否存在公钥..."
    if [ ! -s ~/.ssh/authorized_keys ]; then
        echo "❌ 没有找到有效公钥，无法关闭密码登录。"
        read -p "按回车键返回菜单..." 
        return
    fi

    echo "✅ 已检测到公钥，当前文件为 ~/.ssh/authorized_keys"
    echo "是否要关闭密码登录，仅保留密钥登录？（谨慎操作，确保你已经测试过密钥可以登录）"
    echo "1. 是，只允许密钥登录"
    echo "2. 否，保留密码登录"

    read -p "请输入选项 [1/2]: " opt
    if [ "$opt" != "1" ]; then
        echo "⏭️ 跳过修改，返回菜单"
        return
    fi

    SSHD_CONFIG="/etc/ssh/sshd_config"
    cp $SSHD_CONFIG ${SSHD_CONFIG}.bak

    sed -i 's/^#\?\s*PasswordAuthentication.*/PasswordAuthentication no/' $SSHD_CONFIG
    sed -i 's/^#\?\s*PermitRootLogin.*/PermitRootLogin prohibit-password/' $SSHD_CONFIG
    sed -i 's/^#\?\s*PubkeyAuthentication.*/PubkeyAuthentication yes/' $SSHD_CONFIG

    echo "🔄 正在重启 SSH 服务..."
    if command -v systemctl &> /dev/null; then
        systemctl restart ssh || systemctl restart sshd
    else
        service ssh restart || service sshd restart
    fi

    echo ""
    echo "✅ 已关闭密码登录，仅允许密钥登录。"
    echo "⚠️ 请确保你已经使用私钥成功连接测试过，否则将无法再次连接此 VPS！"
    echo ""
    read -p "按回车键返回菜单..." 
}



start_menu(){
    clear
    echo && echo -e "Across Script
    0. 手动更新脚本
    ———Preset———
    1. 修改时区
    2. 安装BBR

    ————系统设置————
    3. 设置 root 密码
	
    ————密码管理————
  	15. 添加 SSH 公钥（Across2025_key）
	16. 添加 SSH 端口 22
 	17. 检查公钥并关闭密码登录（仅限密钥登录）


    ————V2ray—————
    5. 安装v2ray-agent

    ————Docker—————
    6. 安装docker& docker-compose
    7. 下载docker-compose
    8. 下载XrayR
    9. 修改XrayR/config
    10. 启动docker-compose
    11. 一键安装XrayR

    ————XrayRScript————
    12. 一键安装XrayR-Script
    13. 显示当前XrayR-script NodeID
    14. 删除全部 Docker 容器

 
    ————Legacy————
    50. 初次对接数据库
    51. 删除docker_ssrmu
    52. 添加新的cron管理docker
    53. 一键安装ssr
    54. 一键删除ssr

    ———————————————
    99. 退出"
   

    echo
    read -p " 请输入数字: " num
    case "$num" in
    0) manual_update_script;;
    1) date_setting;;
    2) download_bbr;;
    3) set_root_password;;
    
    5) v2ray_sspanel_install;;
    6) install_docker;;
    7) download_dockercompose;;
    8) download_XrayR;;
    9) edit_configyml;;
    10) start_dockercompose;;
    11) one_click_install_XrayR;;
    12) X2rayR_script_install;;
    13) show_nodeid;;
    14) remove_all_docker_containers;;
	
	15) add_ssh_pubkey;;
 	16) add_ssh_port_22;;
  	17) only_allow_ssh_key_login;;
    50) docker_deploy;;
    51) remove_ssrmu;;
    52) edit_new_cron;;
    53) one_click_install_for_across;;
    54) one_click_uninstall_for_across;;
    99) exit 1;;
    *) clear; echo -e "请输入正确数字"; sleep 2s; start_menu;;
    esac
}

date_setting
start_menu


