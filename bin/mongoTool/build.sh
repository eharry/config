#!/bin/bash

currentDir=$(dirname $(readlink -f $0))
version=3.2.18

cd code/dds/code


#scons MONGO_VERSION=$version LINKFLAGS="-static-libstdc++" -c
scons MONGO_VERSION=$version LINKFLAGS="-static-libstdc++" core --ssl -j 2
scons MONGO_VERSION=$version LINKFLAGS="-static-libstdc++" mongobridge --ssl -j 2
