#!/bin/bash

cmd="$1"

usage() {
echo "op.sh k"
echo "op.sh s"
echo "op.sh q"
echo "op.sh prepareDisk"
echo "op.sh initRepl"
echo "op.sh createUser"
echo "op.sh clean"
echo "op.sh runYCSB ip workload threadNumber [load|run]"
echo "op.sh dropDatabase database"
echo "op.sh showdbs"
}

mongod=/exDisk/package/bin/mongod
mongo=/exDisk/package/bin/mongo
configFile=/exDisk/package/replConf/repl.conf
baseDir=/exDisk/package

if [ "x${cmd}" = "xs" ]; then
  ${mongod} -f ${configFile}
elif [ "x${cmd}" = "xk" ]; then
  ps -ef | grep "mongod -f" | awk '{print $2}' | xargs kill -9
elif [ "x${cmd}" = "xq" ]; then
  ps -ef | grep "mongod " 
elif [ "x${cmd}" = "xclean" ]; then
  rm -rf /exDisk/package/dbPath/*
elif [ "x${cmd}" = "xrunYCSB" ]; then
  mongoUrl="mongodb://rwuser:Gauss_123@$2:27017/test?authSource=admin"
  workload="$3"
  number=$4
  action=$5
  export JAVA_HOME=/tmp/jdk1.8.0_172
  export CLASSPATH=$CLASSPATH:$JAVA_HOME/lib:$JAVA_HOME/jre/lib
  export PATH=$JAVA_HOME/bin:$JAVA_HOME/jre/bin:$PATH:$HOMR/bin
  cd /tmp/
  ycsb/bin/ycsb ${action} mongodb -threads ${number} -s -P ${workload} -p mongodb.url=${mongoUrl} 
  
elif [ "x${cmd}" = "xprepareDisk" ]; then
  fdisk /dev/vdb <<EOF
n
p



w
EOF
  mkfs.ext4 /dev/vdb1
  echo "/dev/vdb1 /exDisk                   ext4    defaults        1 2" >> /etc/fstab
  mount -a
  df -h 
elif [ "x${cmd}" = "xshowdbs" ]; then
  ${mongo} <<EOF
  use admin
  db.auth('rwuser','Gauss_123')
  show dbs
  exit
EOF
elif [ "x${cmd}" = "xdropDatabase" ]; then
  db=$2
  echo "db is $db"
  ${mongo} <<EOF
  use admin
  db.auth('rwuser','Gauss_123')
  use $db
  db.dropDatabase() 
  show dbs
  exit
EOF
elif [ "x${cmd}" = "xinitRepl" ]; then
  ${mongo} ${baseDir}/init.real.js   
elif [ "x${cmd}" = "xcreateUser" ]; then
  ${mongo} mongodb://127.0.0.1/admin ${baseDir}/createUser.js   
else
  usage
fi
