#!/bin/bash

opwd=$PWD
echo "$opwd"
for testfile in `find . -name "Test*"`;
do
  echo "[ $testfile ]"
  sleep 1
  cd "$(dirname $testfile)"
  iverilog -g2012 "$(basename $testfile)"
  vvp a.out
  cd "$opwd"
done