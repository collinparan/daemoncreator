#!/usr/bin/env bash

######To run with args
# https://stackoverflow.com/questions/1410976/equivalent-of-bash-backticks-in-python#answer-1411004
# https://unix.stackexchange.com/questions/24952/script-to-monitor-folder-for-new-files#answer-500074
# sudo systemctl start myseervic@"arg1 arg2 arg3".service
######Monitoring a file
# https://unix.stackexchange.com/questions/24952/script-to-monitor-folder-for-new-files#answer-500074
######

function daemon_setup(){
    DEFAULT_DAEMON_NAME="new_daemon";
    DEFAULT_DAEMON_DESC="Generic Daemon Description";
    AUTO_RESTART_ON_REBOOT="yes";
    DEFAULT_DAEMON_RUN="/usr/bin/env python /root/hello_world.py";
    DEFAULT_START_DAEMON="no";
    DEFAULT_ACCEPT_ARGS="no";
    read -p "Enter a daemon name [$DEFAULT_DAEMON_NAME]: " daemon_name;
    daemon_name="${daemon_name:-$DEFAULT_DAEMON_NAME}";
    read -p "Enter a daemon description [$DEFAULT_DAEMON_DESC]: " daemon_description;
    daemon_description="${daemon_description:-$DEFAULT_DAEMON_DESC}";
    read -p "Would you like \"$daemon_name\" daemon to auto-restart everytime the VM reboots? [$AUTO_RESTART_ON_REBOOT]: " autorestart_option;
    autorestart_option="${autorestart_option:-$AUTO_RESTART_ON_REBOOT}";
    if [[ $autorestart_option = "yes" ]]
    then
        autorestart_string="LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
Restart=on-failure"
    else
        autorestart_string = "  "
    fi;
    read -p "Will your service accept script arguments? [$DEFAULT_ACCEPT_ARGS]: " accept_args;
    accept_args="${accept_args:-$DEFAULT_ACCEPT_ARGS}";
    if [[ $accept_args = "yes" ]]
    then
        accept_args_string="Environment=\"SCRIPT_ARGS=%I\""
        accept_args_string_add="\$SCRIPT_ARGS"
    else
        accept_args_string = "  "
        accept_args_string_add="  "
    fi;
    read -p "Would you like \"$daemon_name\" daemon to run? [$DEFAULT_DAEMON_RUN]: " daemon_run;
    daemon_run="${daemon_run:-$DEFAULT_DAEMON_RUN}";
    cd /etc/systemd/system/ && echo "[Unit]
    Description=$daemon_description
    After=network-online.target
    Wants=network-online.target systemd-networkd-wait-online.service

    [Service]
    Type=simple
    $autorestart_string

    $accept_args_string
    ExecStart=$daemon_run $accept_args_string_add

    [Install]
    WantedBy=multi-user.target" > $daemon_name.service;
    echo "Reloading daemon services...";
    sudo systemctl daemon-reload;
    echo "Enabling $daemon_name.service...";
    sudo systemctl enable $daemon_name.service;
    read -p "Would you like to start \"$daemon_name\" daemon now? [$DEFAULT_START_DAEMON]: " start_daemon;
    start_daemon="${start_daemon:-$DEFAULT_START_DAEMON}";
    if [[ $start_daemon = "no" ]]
    then
        echo "Done"
    else
        sudo systemctl start $daemon_name.service
    fi;
    echo "Checking status of $daemon_name.service...";
    sudo systemctl status $daemon_name.service;
}

function start_daemon(){
    DEFAULT_DAEMON="hello_world.service";
    read -p "Which daemon would you like to start? [$DEFAULT_DAEMON] " daemon_fullname;
    daemon_fullname="${daemon_fullname:-$DEFAULT_DAEMON}";
    echo "Starting $daemon_fullname...";
    sudo systemctl start $daemon_fullname;
    echo "Checking status of $daemon_fullname...";
    sudo systemctl status $daemon_fullname;
}

function stop_daemon(){
    DEFAULT_DAEMON="hello_world.service";
    read -p "Which daemon would you like to stop? [$DEFAULT_DAEMON] " daemon_fullname;
    daemon_fullname="${daemon_fullname:-$DEFAULT_DAEMON}";
    echo "Stopping $daemon_fullname...";
    sudo systemctl stop $daemon_fullname;
    echo "Checking status of $daemon_fullname...";
    sudo systemctl status $daemon_fullname;
}


function check_daemon_status(){
    DEFAULT_DAEMON="hello_world.service";
    read -p "Which daemon do you want to check status? [$DEFAULT_DAEMON] " daemon_fullname;
    daemon_fullname="${daemon_fullname:-$DEFAULT_DAEMON}";
    echo "Ok, checking status of $daemon_fullname...";
    sudo systemctl status $daemon_fullname;
}

function list_all_systemctl_services(){
    (systemctl list-units --type service);
    #(systemctl list-units);
    #systemctl list-units -a --state=inactive;
    #systemctl list-units -a --state=active;
}

function delete_daemon(){
    DEFAULT_CHOICE="no";
    read -p "Enter a daemon name: " daemon_name;
    echo "Warning: This will delete $daemon_name";
    read -p "Type \"y\" to continue? [$DEFAULT_CHOICE] " continue_choice;
    continue_choice="${continue_choice:-$DEFAULT_CHOICE}";
    if [[ $continue_choice = "no" ]]
    then
        echo "Exited without deleting $daemon_name"
    else
        echo "Deleting $daemon_name ..." &&
        sudo systemctl stop $daemon_name &&
        sudo systemctl disable $daemon_name &&
        sudo rm /etc/systemd/system/$daemon_name &&
        sudo rm /etc/init.d/$daemon_name &&
        sudo systemctl daemon-reload &&
        sudo systemctl reset-failed &&
        echo "Successfully deleted $daemon_name" 
    fi;    
}


echo "What would you like to setup or do?"
select pd in "daemon_setup" "start_daemon" "stop_daemon" "check_daemon_status" "delete_daemon" "list_all_systemctl_services" "exit"; do 
    case $pd in 
        daemon_setup) daemon_setup; exit;;
        start_daemon) start_daemon; exit;;
        stop_daemon) stop_daemon; exit;;
        check_daemon_status) check_daemon_status; exit;;
        delete_daemon ) delete_daemon; exit;;
        list_all_systemctl_services) list_all_systemctl_services; exit;;
        exit ) exit;;
    esac
done
