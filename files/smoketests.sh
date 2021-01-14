#!/bin/bash

TESTDIR="/marvin/tests/smoke"
LOGDIR="/marvin/log"

mkdir -p $LOGDIR

NUMTESTS=`find $TESTDIR/test_*.py | wc -l`
run_start_time="$(date -u +%s)"
counter=1
PASSES=0
FILES=$(ls $TESTDIR/test_*py | grep -v test_host_maintenance | grep -v test_hostha_kvm)
if [ -f /$TESTDIR/test_host_maintenance.py ]; then
    FILES="$FILES $TESTDIR/test_host_maintenance.py"
fi
if [ -f $TESTDIR/test_hostha_kvm.py ]; then
    FILES="$FILES $TESTDIR/test_hostha_kvm.py"
fi

for file in $FILES; do
  echo "Starting test: $file"
  nosetests-2.7 --with-xunit --xunit-file=$LOGDIR/$(basename $file).xml --with-marvin --marvin-config=marvin.cfg -s -a tags=advanced $file
done

