#!/bin/bash


. conf
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
#    copyFile ${ips[0]} op.sh /tmp/op.sh
    exeRemoteCmd ${ips[0]} "/tmp/op.sh ${cmd} $2"
  else
#    copyFiles op.sh /tmp/op.sh
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
#  exeRemoteCmd ${clientIp} "/tmp/op.sh runYCSB ${ips[0]} $workload $n $f" 
  exeRemoteCmd ${clientIp} "/tmp/op.sh runYCSB ${ips[0]} $workload $n $f" > utlog/$logFile
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

mtuFun() {
  local eth=$1
  local mtuNumber=$2
  exeRemoteCmds "ifconfig $eth mtu $mtuNumber; ifconfig"
  exeRemoteCmd ${clientIp} "ifconfig $eth mtu $mtuNumber; ifconfig" 
}


calcOffset() {
  local functionName=$1
  local offset=$2
  local addr=$3
  local debugBinaryPath=$4
 
  local readOnlyFunctionName=`c++filt _ZN5mongo22WiredTigerSessionCache14releaseSessionEPNS_17WiredTigerSessionE | sed 's/(.*//g'`
  local resultStr=`nm -C $debugBinaryPath | grep "$readOnlyFunctionName"`
  echo "resultStr: $resultStr"
  local count=`nm -C $debugBinaryPath | grep "$readOnlyFunctionName"| wc -l`
  if [ $count -gt 1 ]; then
    nm -C $debugBinaryPath | grep "$readOnlyFunctionName"
    echo "please input the index which function is right: such as 1 2 3"
    read inputIndex
    resultStr="echo $resultStr | sed -n ${inputIndex}p"
  elif [ $count -eq 0 ]; then
    echo "cannot find the function, need recheck the input"
    exit 1
  fi
  
  local addr1=`echo $resultStr | awk '{print $1}'`
  addr1="0x$addr1"
  local offsetReal=$[addr - addr1 - offset]
  echo "offsetReal is $offsetReal"
}

usage() {
  echo "run.sh loadMongodbDisk"
  echo "run.sh deployMongoBinary path"
  echo "run.sh configReplica"
  echo "run.sh remoteCmd [k|s|q|initRepl|createUser|clean|showdbs|dropDatabase database|remount options|cleanAuditLog|shutdownOpLog]"
  echo "run.sh deployYCSB"
  echo "run.sh runYCSB workload threadNum [load|run] logPath"
  echo "run.sh updateAdminWhiteList"
  echo "run.sh mtu eth number"
  echo "run.sh calcOffset functionName offset1 addr debugBinaryPath"
  echo "run.sh showStack offset debugBinaryPath addr[ ...]"
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
elif [ "$cmd" = "mtu" ]; then
  mtuFun $2 $3
elif [ "$cmd" = "calcOffset" ]; then
  calcOffset $2 $3 $4 $5
elif [ "$cmd" = "showStack" ]; then
  offset=$2
  debugBinaryPath=$3
  shift 3

  until [ $# -eq 0 ]
  do
    inputAddr=$1
    printf -v realAddr "%#x" $[inputAddr - offset]
    addr2line -e $debugBinaryPath -ifC $realAddr
    shift
  done
  
else
  usage
fi

