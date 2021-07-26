#!/bin/bash
### 一键安装 speedtest go-arm 版本  #
###    作者：n0thing2speak
 #
###   更新时间：2020-07-27      #

#导入环境变量
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/bin:/sbin
export PATH
dir="/usr/speedtest/"

function setout(){
    if [ -e "/usr/bin/yum" ]; then
        yum -y install git wget
    else
        sudo apt-get update
        sudo apt-get install -y wget git
    fi
}

function chk_firewall(){
    if [ -e "/etc/sysconfig/iptables" ]; then
        iptables -I INPUT -p tcp --dport $port -j ACCEPT
        service iptables save
        service iptables restart
    elif [ -e "/etc/firewalld/zones/public.xml" ]; then
        firewall-cmd --zone=public --add-port=$port/tcp --permanent
        firewall-cmd --reload
    elif [ -e "/etc/ufw/before.rules" ]; then
        sudo ufw allow $port/tcp
    fi
}

function del_post() {
    if [ -e "/etc/sysconfig/iptables" ]; then
        sed -i "/^.*$port.*/"d /etc/sysconfig/iptables
        service iptables save
        service iptables restart
    elif [ -e "/etc/firewalld/zones/public.xml" ]; then
        firewall-cmd --zone=public --remove-port=$port/tcp --permanent
        firewall-cmd --reload
    elif [ -e "/etc/ufw/before.rules" ]; then
        sudo ufw delete $port/tcp
    fi
}

function install_go(){
    apt isntall go -y
}

function input_port(){
    while true
        do
        read -p "请输入监听端口[1-65535]（默认8989）:" port
        [[ -z "${port}" ]] && port="8989"
        echo $((${port}+0)) &>/dev/null
        if [[ $? -eq 0 ]]; then
            if [[ ${port} -ge 1 ]] && [[ ${port} -le 65535 ]]; then
                echo "设置端口:${port}"
                break
            else
                echo "输入错误, 请输入正确的端口."
            fi
        else
            echo "输入错误, 请输入正确的端口."
        fi
        done
}

function change_port(){
    stop
    sleep 2
    input_port
    del_post
    chk_firewall
    cd $dir && sed -i "4s/[0-9]\{1,5\}/$port/g" settings.toml
    start
}

function get_speedtest(){
    if [ -e $dir"speedtest" ]; then
        echo "已经安装，将更新到最新版."
        rm -rf $dir
    fi
    install_go
    cd && git clone https://github.com/librespeed/speedtest-go.git
    cd speedtest-go
    mkdir $dir && cp -r settings.toml assets $dir
    go build -o speedtest main.go
    cp ./speedtest $dir
    cd && rm -rf speedtest 
    cd $dir && sed -i "4s/[0-9]\{1,5\}/$port/g" settings.toml
    cd $dir"assets" && mv example-singleServer-full.html index.html
    
}

function start(){
    PID=`pgrep speedtest`
    if [ ! -z $PID ]; then
        echo "已经启动."
        return
    else
        cd $dir && nohup ./speedtest > /var/log/speedtest.log 2>&1 &
        echo "------------------------------------------------"
        echo "启动成功."
        echo "访问IP:$port测速."
    fi
    
}

function stop(){
    PID=`pgrep speedtest`
    if [ ! -z ${PID} ]; then
        kill -9 ${PID}
        echo "停止成功."
    else
        echo "没有启动."
    fi
}


function del(){
    stop
    del_post
    rm -rf $dir
    rm -f /var/log/speedtest.log
    echo "卸载成功."
}

function thread_set(){
    read -p "输入要设置的线程大小:" number
    expr $number + 1 >/dev/null 2>&1
    [ $? -ne 0 ] && echo "请输入一个确定的数字" && exit 8 || sed -i "s/xhr_dlMultistream: [0-9]*,/xhr_dlMultistream: $number,/g" $dir/assets/speedtest_worker.js && sed -i "s/xhr_ulMultistream: [0-9]*,/xhr_ulMultistream: $number,/g" $dir/assets/speedtest_worker.js && stop && sleep 2 && start && echo "设置成功,刷新网页即可"

}

function time_set(){
    read -p "输入要设置的时间大小(单位为s):" number
    expr $number + 1 >/dev/null 2>&1
    [ $? -ne 0 ] && echo "请输入一个确定的数字" && exit 8 || sed -i "s/time_ul_max: [0-9]*,/time_ul_max: $number,/g" $dir/assets/speedtest_worker.js && sed -i "s/time_dl_max: [0-9]*,/time_dl_max: $number,/g" $dir/assets/speedtest_worker.js && stop && sleep 2 && start && echo "设置成功,刷新网页即可"
}

echo "------------------------------------------------"
echo "Speedtest go-ARM一键安装管理脚本"
echo "1、安装 Speedtest"
echo "2、卸载 Speedtest"
echo "3、修改监听端口"
echo "4、启动 Speedtest"
echo "5、停止 Speedtest"
echo "6、设置多线程上传下载"
echo "7、设置测速时长(秒为单位)"
echo "其它键退出！"
read -p ":" istype
case $istype in
    1)
    input_port
    setout
    get_speedtest
    chk_firewall
    start;;
    2)
    del;;
    3)
    change_port;;
    4)
    start;;
    5)
    stop;;
    6)
    thread_set;;
    7)
    time_set;;
    *) break
esac
