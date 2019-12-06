#!/bin/bash

PATH_LOCATION=
DOCKER_IMAGE_NAME=ws-aria2
PORT_RPC=6800
PORT_BT=6801
PORT_DHT=6802
PORT_WEB=6808
RPC_SECRET=
DOCKER_FILE=Dockerfile
CONFIG_FILE=aria2.conf
CONFIG_NGINX=nginx.conf

COLOR_ERROR="31m"
COLOR_SUCCESS="32m"
COLOR_WARNING="33m"

function print_color()
{
    echo -e "\033[${1}${2}\033[0m"
}

function check()
{
    ${2}
    ret=${?}
    if [ ${ret} -eq 0 ];
    then
        print_color ${COLOR_SUCCESS} "[${1}]环境已准备好."
    else
        print_color ${COLOR_ERROR} "[${1}]环境未准备好，请先安装[${1}]."
    fi
    return ${ret}
}

function check_docker()
{
    check docker "docker -v"
}

function clear_env()
{
    docker stop ${DOCKER_IMAGE_NAME}
    docker rm ${DOCKER_IMAGE_NAME}
    docker rmi ${DOCKER_IMAGE_NAME}
}

function options_location()
{
    read -p "$(print_color ${COLOR_SYSTEM} 'aria2 location path [/data/aria2-data]: ')" PATH_LOCATION
    if [ -z "${PATH_LOCATION}" ];
    then
        PATH_LOCATION="/data/aria2-data"
    fi
    
    read -p "$(print_color ${COLOR_SYSTEM} 'aria2 docker rpc secret [default_token]: ')" RPC_SECRET
    if [ -z "${RPC_SECRET}" ];
    then
        RPC_SECRET="default_token"
    fi
}

function options_port()
{
    while true
    do
        output=`netstat -anp | grep LISTEN | grep ${PORT_RPC}`
        if [ -n "${output}" ];
        then
            let POST_RPC+=10
        else
            break
        fi
    done

    while true
    do
        output=`netstat -anp | grep LISTEN | grep ${PORT_BT}`
        if [ -n "${output}" ];
        then
            let PORT_BT+=10
        else
            break
        fi
    done
    
    while true
    do
        output=`netstat -anp | grep LISTEN | grep ${PORT_DHT}`
        if [ -n "${output}" ];
        then
            let PORT_DHT+=10
        else
            break
        fi
    done
    
    while true
    do
        output=`netstat -anp | grep LISTEN | grep ${PORT_WEB}`
        if [ -n "${output}" ];
        then
            let PORT_WEB+=10
        else
            break
        fi
    done
}

function init_port()
{
    sed -i s/OCC_PORT_RPC/${PORT_RPC}/g ${DOCKER_FILE}
    sed -i s/OCC_PORT_BT/${PORT_BT}/g ${DOCKER_FILE}
    sed -i s/OCC_PORT_DHT/${PORT_DHT}/g ${DOCKER_FILE}
    sed -i s/OCC_PORT_WEB/${PORT_WEB}/g ${DOCKER_FILE}
    sed -i s/OCC_RPC_SECRET/${RPC_SECRET}/g ${DOCKER_FILE}
}

function init_location()
{
    options_location
    
    mkdir -p ${PATH_LOCATION}
}

function build_image()
{
    docker build -f Dockerfile -t ${DOCKER_IMAGE_NAME} .
}

function start_container()
{
    docker run -d \
        --name ${DOCKER_IMAGE_NAME} \
        -e ENV_PORT_RPC=${PORT_RPC} \
        -e ENV_PORT_BT=${PORT_BT} \
        -e ENV_PORT_DHT=${PORT_DHT} \
        -e ENV_PORT_WEB=${PORT_WEB} \
        -e ENV_RPC_SECRET=${RPC_SECRET} \
        -v ${PATH_LOCATION}"/download":/opt/aria2/download \
        -p ${PORT_BT}:${PORT_BT} \
        -p ${PORT_DHT}:${PORT_DHT} \
        -p ${PORT_RPC}:${PORT_RPC} \
        -p ${PORT_WEB}:${PORT_WEB} \
        ${DOCKER_IMAGE_NAME}
}

function main()
{
    print_color ${COLOR_WARNING} "检查本地Docker环境开始..."
    check_docker
    if [ ${?} -ne 0 ];
    then
        print_color ${COLOR_ERROR} "退出"
        exit 1
    fi
    
    print_color ${COLOR_WARNING} "清理Docker环境开始..."
    clear_env
    print_color ${COLOR_SUCCESS} "清理Docker环境完成."
    
    print_color ${COLOR_WARNING} "初始化本地目录开始..."
    init_location
    print_color ${COLOR_SUCCESS} "初始化本地目录完成."
    
    print_color ${COLOR_WARNING} "初始化本地端口开始..."
    options_port
    init_port
    print_color ${COLOR_SUCCESS} "初始化本地端口完成."
    
    print_color ${COLOR_WARNING} "编译aria2镜像开始..."
    build_image
    print_color ${COLOR_SUCCESS} "编译aria2镜像完成."
    
    print_color ${COLOR_WARNING} "启动容器开始..."
    start_container
    print_color ${COLOR_SUCCESS} "启动容器完成."
    
    print_color ${COLOR_SUCCESS} "aria2启动成功："
    print_color ${COLOR_SUCCESS} "BT端口 : ${PORT_BT}"
    print_color ${COLOR_SUCCESS} "DHT端口: ${PORT_DHT}"
    print_color ${COLOR_SUCCESS} "RPC端口: ${PORT_RPC}"
    print_color ${COLOR_SUCCESS} "WEB端口: ${PORT_WEB}"
}

main
