#!/bin/bash

ips=(
"192.168.0.137"
"192.168.0.185"
"192.168.0.161"
)
password="Gauss_123"
jdkPackage="jdk-8u172-linux-x64.tar.gz"
clientIp="192.168.0.42"

# ------------------------------------------------------------------------
function copyFile() {
  ip=$1
  srcFileName=$2
  targetFileName=$3
  
  expect -c "
  set timeout 1000;
  spawn scp -p ${srcFileName} root@${ip}://${targetFileName}
  expect {
    *yes/no* { send \"yes\r\"; exp_continue }
    *assword* { send \"${password}\r\" }
  };
  expect eof;
  "
}

function exeRemoteCmd() {
  ip=$1
  cmd=$2

  expect -c "
  set timeout 1000;
  spawn ssh root@${ip} \"hostname; $cmd \"
  expect {
    *yes/no* { send \"yes\r\"; exp_continue }
    *assword* { send \"${password}\r\" }
  };
  expect eof;
  "

}

function exeRemoteCmds()
{
  cmd=$1
  for ip in ${ips[@]};do
    exeRemoteCmd $ip "$cmd"
  done
}

function copyFiles()
{
  srcFileName=$1
  targetFileName=$2
  for ip in ${ips[@]};do
   echo $ip
   copyFile $ip "${srcFileName}" "${targetFileName}"
  done
}
#-------------------------------------------

# fdisk the /dev/vcb and mount to /exDisk
loadMongodbDiskFun() {
  exeRemoteCmds "mkdir -p /exDisk; ls -l /exDisk"
  copyFiles op.sh /tmp/op.sh
  exeRemoteCmds "/tmp/op.sh prepareDisk"
}

configReplicaFun() {
  exeRemoteCmds "mkdir -p /exDisk/package/replConf; ls -l /exDisk"
  exeRemoteCmds "mkdir -p /exDisk/package/dbPath; ls -l /exDisk"

  # config keyfile
  chmod 400 keyfile
  copyFiles keyfile /exDisk/package/keyfile
  exeRemoteCmds "chmod 400 /exDisk/package/keyfile"

  # change init.js
  cp init.js init.real.js
  cnt=1
  for ip in ${ips[@]};do
    sed -i "s/HOST_TEMP${cnt}/$ip/g" init.real.js
    ((cnt=cnt+1))
  done

  
  copyFiles init.real.js /exDisk/package/init.real.js
  copyFiles createUser.js /exDisk/package/createUser.js

  updateAdminWhiteListFun
  
  # change config
  copyFiles replConf/repl.conf /exDisk/package/replConf/repl.conf
  for ip in ${ips[@]};do
    exeRemoteCmd $ip "sed -i 's/127.0.0.1/127.0.0.1,$ip/g' /exDisk/package/replConf/repl.conf"
  done

  rm -rf init.real.js
}

deployMongoBinaryFun() {
  exeRemoteCmds "rm -rf /exDisk/package/bin; mkdir -p /exDisk/package/bin"
  copyFiles $1/mongod /exDisk/package/bin/mongod
  copyFiles $1/mongos /exDisk/package/bin/mongos
  copyFiles $1/mongo /exDisk/package/bin/mongo
  exeRemoteCmds "ls -l /exDisk/package/bin/"
}

remoteCmdFun() {
  local cmd="$1"
  if [ "x$cmd" = "xinitRepl" -o "x$cmd" = "xcreateUser" -o "x$cmd" = "xshowdbs" -o "x$cmd" = "xdropDatabase" ]; then
    copyFile ${ips[0]} op.sh /tmp/op.sh
    exeRemoteCmd ${ips[0]} "/tmp/op.sh ${cmd} $2"
  else
    copyFiles op.sh /tmp/op.sh
    exeRemoteCmds "/tmp/op.sh ${cmd} $2"
  fi
#exeRemoteCmds "/tmp/op.sh clean"
#exeRemoteCmds "/tmp/op.sh q"
#exeRemoteCmds "/tmp/op.sh s"
#exeRemoteCmd ${ips[0]} "/tmp/op.sh initRepl"
#sleep 20
#exeRemoteCmd ${ips[0]} "/tmp/op.sh createUser"
}

deployYCSBFun() {
  copyFile $clientIp ./${jdkPackage} /tmp/
  copyFile $clientIp ./ycsb.tar.gz /tmp/
  copyFile $clientIp ./python.tar.gz /tmp/
  exeRemoteCmd $clientIp "cd /tmp; tar -xvzf ${jdkPackage}; tar -xvzf ycsb.tar.gz; chmod +x /tmp/ycsb/bin/ycsb; tar -xvzf python.tar.gz; cp -rf python/* /var/cache/apt/archives/; apt install -y python"
}

runYCSBFun() {
  local workload=$1
  local n=$2
  local f=$3
  local logFile=$4
  copyFile $clientIp $workload /tmp/
  copyFile $clientIp op.sh /tmp/
  exeRemoteCmd ${clientIp} "/tmp/op.sh runYCSB ${ips[0]} $workload $n $f" 
#  exeRemoteCmd ${clientIp} "/tmp/op.sh runYCSB ${ips[0]} $workload $n $f" > utlog/$logFile
}

updateAdminWhiteListFun() {
  # generate the whiteList
  ipList="127.0.0.1" 
  for ip in ${ips[@]};do
    ipList="$ipList,$ip"
  done
  echo "$ipList" > adminWhiteList
  
  copyFiles adminWhiteList /exDisk/package/adminWhiteList
}

usage() {
  echo "run.sh loadMongodbDisk"
  echo "run.sh deployMongoBinary path"
  echo "run.sh configReplica"
  echo "run.sh remoteCmd [k|s|q|initRepl|createUser|clean|showdbs|dropDatabase database|remount options|cleanAuditLog|shutdownOpLog]"
  echo "run.sh deployYCSB"
  echo "run.sh runYCSB workload threadNum [load|run] logPath"
  echo "run.sh updateAdminWhiteList"
}

# ------------------------ main -------------------------
cmd=$1

if [ "x$cmd" = "x" ]; then
  usage
elif [ "$cmd" = "loadMongodbDisk" ]; then
  loadMongodbDiskFun
elif [ "$cmd" = "configReplica" ]; then
  configReplicaFun
elif [ "$cmd" = "deployMongoBinary" ]; then
  deployMongoBinaryFun $2
elif [ "$cmd" = "remoteCmd" ]; then
  remoteCmdFun $2 $3
elif [ "$cmd" = "deployYCSB" ]; then
  deployYCSBFun
elif [ "$cmd" = "runYCSB" ]; then
  runYCSBFun $2 $3 $4 $5
elif [ "$cmd" = "updateAdminWhiteList" ]; then
  updateAdminWhiteListFun 
else
  usage
fi

