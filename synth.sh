#!/bin/bash

opwd=$PWD
echo "$opwd"
for testfile in `find . -name "config.ys"`;
do
  cd "$(dirname $testfile)"
  yosys -l ./yosys.log -v2 "$(basename $testfile)"
  cd "$opwd"
done