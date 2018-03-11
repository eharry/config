#!/bin/bash

usage()
{
    echo "$0 [mysql1|mysql2|mysql3] [status|start|stop|connect|reinstall]"
}

checkParameters()
{
    if [ "x${mysqlSelect}" != "xmysql1" -a "x${mysqlSelect}" != "xmysql2" -a "x${mysqlSelect}" != "xmysql3" ]; then
        echo "mysqlSelect(${mysqlSelect}) should be mysql1, mysql2, mysql3. "
        usage
        exit
    fi

    if [ "x${operation}" != "xstart" -a "x${operation}" != "xstop" -a "x${operation}" != "xstatus" -a "x${operation}" != "xconnect" -a "x${operation}" != "xreinstall" ]; then
        echo "operation(${operation}) should be start, stop , connect, reinstall or status"
        usage
        exit
    fi
}

reinstall()
{
    rm -rf ${dataDirPath}/data/*
    echo "init datadir to ${dataDirPath}" >> /tmp/1
    mysqld --initialize --datadir=${dataDirPath}/data --user=eharry --basedir=/home/eharry/app/mysql/bin/ >> /tmp/1 2>&1
#    rm -rf ${dataDirPath}/data/ibdata1
#    rm -rf ${dataDirPath}/data/ib_logfile*
}

# ---- main -----
if [ $# -lt 2 ]; then
    echo "input parameters count should be more than 2"
    usage
    exit
fi


mysqlSelect="$1"
operation="$2"
confFilePath=""
dataDirPath=""
user="root"
socketFile=""

checkParameters


if [ "x${mysqlSelect}" = "xmysql1" ]; then
    dataDirPath=/home/eharry/app/mysql/data
elif [ "x${mysqlSelect}" = "xmysql2" ]; then
    dataDirPath=/home/eharry/app/mysql/data2
elif [ "x${mysqlSelect}" = "xmysql3" ]; then
    dataDirPath=/home/eharry/app/mysql/data3
fi

confFilePath=${dataDirPath}/conf/my.cnf
socketFile=${dataDirPath}/mysql.sock


if [ "${operation}" = "start" ]; then
    mysqld --defaults-file=${confFilePath} &
elif [ "${operation}" = "stop"  ]; then
    mysqladmin shutdown -u ${user} -p -S ${socketFile}
elif [ "${operation}" = "status" ]; then
    :
elif [ "${operation}" = "connect" ]; then
    mysql -u root -p -S ${socketFile}
elif [ "${operation}" = "reinstall" ]; then
    reinstall
fi



