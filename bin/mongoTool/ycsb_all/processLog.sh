#!/bin/bash


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

cd utlog1/
grep 'Return' -r . | grep -v 'OK'
if [ $? = 0 ]; then
  echo "some test returen not ok, skip process log"
fi

grep 'Throughput' -r . > /tmp/1
touch /tmp/2
echo "" > /tmp/2


for testSuite in ${testSuites[@]};  
do
  for action in ${actions[@]};  
  do
    for threadNumber in ${threads[@]};  
    do  
      result=`cat /tmp/1 | grep "/${threadNumber}\." | grep $action | grep $testSuite | sed 's/.*), //g' | sed 's/\..*//g' | sort | xargs`
      echo "$testSuite,$action,$threadNumber $result" >> /tmp/2
    done 
  done
done

cat /tmp/2





