#!/bin/bash

cmd="$1"
fileName="$0"


mongod="/home/eharry/code/mongodb/3.2.18/mongodb-src-r3.2.18/mongod"

function usage()
{
  echo "$0 n functionname"
  exit 1
}

if [ "x$cmd" = "xn" ]; then
  nm -C "$mongod" | grep "$2"
else
  usage
fi

