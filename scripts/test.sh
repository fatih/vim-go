#!/bin/bash

set -e

cd $(dirname $0)

# cleanup test.log
if [ -f "test.log" ]; then
   rm test.log
fi
if [ -f "messages.log" ]; then
   rm messages.log
fi

fail=0

vim -u NONE -S runtest.vim

# test.log only exists if a test fails, output it so we see it
if [ -f "test.log" ]; then
   fail=1
   cat test.log
fi

if [ -f "messages.log" ]; then
   cat messages.log
else
   fail=1
   echo "Couldn't find messages.log file"
fi

if [ $fail -gt 0 ]; then
  echo 2>&1 "FAIL"
  exit 1
fi
echo 2>&1 "PASS"

