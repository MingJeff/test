#!/bin/bash


#修改时区 Change Date
date_setting(){
    
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    date

}

#安装BBR
download_bbr(){
    wget -N --no-check-certificate "https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh" && chmod +x tcp.sh && ./tcp.sh
}


#安装docker
install_docker(){
    apt-get install curl -y
    docker version > /dev/null || curl -fsSL get.docker.com | bash
    service docker restart
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





start_menu(){
    clear
    echo && echo -e "Across Script
    ———Preset———
    1. 修改时区 Change Date
    2. 安装BBR
    
    ————V2ray—————
    3.安装v2ray-agent
    4.删除docker_v2ray

    ————Docker—————
    13. 安装docker 
    14. 初次对接数据库
    15. 删除docker_ssrmu 
    16. 添加新的cron管理docker

    ————One Click————
    17. 一键安装ssr
    18. 一键删除ssr
    ———————————————
    9. Exit"

    echo
    read -p " 请输入数字:" num
    case "$num" in 
    1)
    date_setting;;
    2)
    download_bbr;;
    3)
    v2ray_sspanel_install;;
    4)
    remove_v2ray;;
    13)
    install_docker;;
    14)
    docker_deploy;;
    15)
    remove_ssrmu;;
    16)
    edit_new_cron;;
    17)
    one_click_install_for_across;;
    18)
    one_click_uninstall_for_across;;
    9)
    exit 1;;
    *)
    clear
    echo -e "请输入正确数字"
    sleep 2s
    start_menu;;
esac
}

date_setting
start_menu


