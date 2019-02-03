#!/bin/bash

opwd=$PWD
echo "$opwd"
for testfile in `find . -name "Test*"`;
do
  cd "$(dirname $testfile)"
  iverilog -g2012 "$(basename $testfile)"
  if [ "$?" != "0" ]; then
    cd "$opwd"
    exit 1
  fi
  vvp a.out
  if [ "$?" != "0" ]; then
    cd "$opwd"
    exit 1
  fi
  cd "$opwd"
done