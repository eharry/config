#!/bin/bash

#./run.sh remoteCmd dropDatabase test

threads=(
16
32
64
128
160
200
)

testSuites=(
"hw1"
"hw2"
)

actions=(
"load"
"run"
)

for testSuite in ${testSuites[@]};  
do
  for action in ${actions[@]};  
  do
    for threadNumber in ${threads[@]};  
    do  
      for((i=1;i<=4;i++));  
      do   
        if [ "$action" = "load" ]; then
#          echo "./run.sh remoteCmd dropDatabase test"
          ./run.sh remoteCmd dropDatabase test
        fi
#        echo "./run.sh runYCSB ${testSuite} $threadNumber $action $threadNumber.$i.$action.${testSuite}.log"
        ./run.sh runYCSB ${testSuite} $threadNumber $action $threadNumber.$i.$action.${testSuite}.log
      done  
    done 
  done
done





#./run.sh remoteCmd dropDatabase test
