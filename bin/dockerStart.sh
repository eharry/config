#!/bin/bash


#imageName="eharry/ubuntu_hexo:002"
#imageName="eharry/ubuntu_base:001"
#imageName="eharry/ubuntu_config:001"
#imageName="eharry/ubuntu_zookeeper:001"
#imageName="eharry/ubuntu_mysql:002"
imageName="eharry/ubuntu_build_mongodb:002"
#imageName="eharry/ubuntu_build_mysql:001"


cmd="/bin/bash"
diskMap="-v /Volumes/disk2/eharry/documents/docker/eharry/dir/home/:/home"




docker run ${diskMap} -i -t ${imageName}  ${cmd}
