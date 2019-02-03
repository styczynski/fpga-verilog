#!/bin/bash

opwd=$PWD
echo "$opwd"
for testfile in `find . -name "Test*.v"`;
do
  cd "$(dirname $testfile)"
  if [ "$(basename $testfile)" = "TestRAM.v" ]; then
    echo "Skipping TestRAM.v ..."
  else
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
  fi
  cd "$opwd"
done