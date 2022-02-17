#!/bin/bash
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

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
  nosetests-3.4 --with-xunit --xunit-file=$LOGDIR/$(basename $file).xml --with-marvin --marvin-config=marvin.cfg -s -a tags=advanced $file
done

