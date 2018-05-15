#!/bin/bash


#imageName="eharry/ubuntu_hexo:002"
#imageName="eharry/ubuntu_base:003"
#imageName="eharry/ubuntu_config:001"
#imageName="eharry/ubuntu_zookeeper:001"
#imageName="eharry/ubuntu_mysql:002"
#imageName="eharry/ubuntu_build_mongodb:004"
imageName="eharry/ubuntu_build_mongodb:004"
#imageName="ubuntu"
#imageName="eharry/ubuntu_build_mysql:001"


cmd="/bin/bash"

diskMap="-v /Volumes/disk2:/data"
#diskMap=""

capSet="--cap-add=SYS_PTRACE"





docker run ${diskMap} ${capSet} -i -t ${imageName} ${cmd}
