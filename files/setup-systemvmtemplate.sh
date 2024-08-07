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


usage() {
  printf "\nUsage: %s:\n\t-m secondary storage mount point\n\t-f system vm template file\n\t-h hypervisor name: kvm|vmware|xenserver|hyperv|ovm3\n\t-s mgmt server secret key, if you specified any when running cloudstack-setup-database, default is password\n\t-u Url to system vm template\n\t-F clean up system templates of specified hypervisor\n\t-e Template suffix, e.g vhd, ova, qcow2\n\n" $(basename $0) >&2
  printf "\tor\n"
  printf "\nUsage: %s:\n\t-m secondary storage mount point\n\t-u http url for system vm template\n\t-h hypervisor name: kvm|vmware|xenserver|hyperv|ovm3\n\t-s mgmt server secret key\n\n" $(basename $0) >&2
}

# Usage: e.g. failed $? "this is an error"
failed() {
  local returnval=$1
  local returnmsg=$2
  
  # check for an message, if there is no one dont print anything
  if [[ -z $returnmsg ]]; then
    :
  else
    echo -e $returnmsg
  fi
  if [[ $returnval -eq 0 ]]; then
    return 0
  elif [[ -n "(echo $returnmsg | grep "already")" ]]; then
    echo $returnmsg
    exit 0
  else
    echo "Installation failed"
    exit $returnval
  fi
}

#set -x
mflag=
fflag=
ext="vhd"
templateId=
hyper=
msKey=password
DISKSPACE=2120000  #free disk space required in kilobytes

# check if first parameter is not a dash (-) then print the usage block
if [[ ! $@ =~ ^\-.+ ]]; then
	usage
	exit 0
fi

OPTERR=0
while getopts 'm:h:f:u:Ft:e:Ms:o:r:d:p:'# OPTION
do
  case $OPTION in
  m)    mflag=1
        mntpoint="$OPTARG"
        ;;
  f)    fflag=1
        tmpltimg="$OPTARG"
        ;;
  u)    uflag=1
        url="$OPTARG"
        ;;
  F)    Fflag=1
        ;;
  t)    templateId="$OPTARG"
        ;;
  e)    ext="$OPTARG"
        ;;
  h)    hyper="$OPTARG"
        ;;
  s)    sflag=1
        msKey="$OPTARG"
        ;;
  ?)    usage
        exit 0
        ;;
  *)    usage
        exit 0
        ;;
  esac
done

if [[ "$mflag$fflag" != "11" && "$mflag$uflag" != "11" ]]; then
  failed 2 "Please add a mount point and a system vm template file"
fi

if [[ -z "$hyper" ]]; then
  failed 2 "Please add a correct hypervisor name like: kvm|vmware|xenserver|hyperv|ovm3"
fi

if [[ ! -d $mntpoint ]]; then
  failed 2 "mount point $mntpoint doesn't exist\n"
fi

if [[ "$fflag" == "1" && ! -f $tmpltimg ]]; then
  failed 2 "template image file $tmpltimg doesn't exist"
fi

if [[ "$templateId" == "" ]]; then
  if [[ "$hyper" == "kvm" ]]; then
    ext="qcow2"
    templateId=3
    qemuimgcmd=$(which qemu-img)
  elif [[ "$hyper" == "xenserver" ]]; then
    ext="vhd"
    templateId=1
  elif [[ "$hyper" == "vmware" ]]; then
    ext="ova"
    templateId=8
  elif [[ "$hyper" == "lxc" ]]; then
    ext="qcow2"
    templateId=3
  elif [[ "$hyper" == "hyperv" ]]; then
    ext="vhd"
    templateId=9
  elif [[ "$hyper" == "ovm3" ]]; then
    ext="raw"
    templateId=12
  else
    failed 2 "Please add a correct hypervisor name like: kvm|vmware|xenserver|hyperv|ovm3"
  fi
fi

if [[ ! $templateId ]]; then
  failed 2 "Unable to get template Id from database"
fi

_uuid=$(uuidgen)
localfile=$_uuid.$ext

mntpoint=`echo "$mntpoint" | sed 's|/*$||'`

destdir=$mntpoint/template/tmpl/1/$templateId/

mkdir -p $destdir
if [[ $? -ne 0 ]]; then
  failed 2 "Failed to write to mount point $mntpoint -- is it mounted?\n"
fi

if [[ "$Fflag" == "1" ]]; then
  rm -rf $destdir/*
  if [[ $? -ne 0 ]]; then
    failed 2 "Failed to clean up template directory $destdir -- check permissions?"
  fi
fi

if [[ -f $destdir/template.properties ]]; then
  failed 2 "Data already exists at destination $destdir -- use -F to force cleanup of old template\nIF YOU ARE ATTEMPTING AN UPGRADE, YOU MAY NEED TO SPECIFY A TEMPLATE ID USING THE -t FLAG"
fi

destfiles=$(find $destdir -name \*.$ext)
if [[ "$destfiles" != "" ]]; then
  failed 2 "Data already exists at destination $destdir -- use -F to force cleanup of old template"
fi

tmplfile=$(dirname $0)/$localfile

touch $tmplfile
if [[ $? -ne 0 ]]; then
  failed 2 "Failed to create temporary file in directory $(dirname $0) -- is it read-only or full?\n"
fi

destcap=$(df -P $destdir | awk '{print $4}' | tail -1 )
[ $destcap -lt $DISKSPACE ] && echo "Insufficient free disk space for target folder $destdir: avail=${destcap}k req=${DISKSPACE}k" && failed 4

localcap=$(df -P $(dirname $0) | awk '{print $4}' | tail -1 )
[ $localcap -lt $DISKSPACE ] && echo "Insufficient free disk space for local temporary folder $(dirname $0): avail=${localcap}k req=${DISKSPACE}k" && failed 4

if [[ "$uflag" == "1" ]]; then
  wget -O $tmplfile $url
  if [[ $? -ne 0 ]]; then
    failed 2 "Failed to fetch system vm template from $url"
  fi
fi

if [[ "$fflag" == "1" ]]; then
  cp $tmpltimg $tmplfile
  if [[ $? -ne 0 ]]; then
    failed 2 "Failed to create temporary file in directory $(dirname $0) -- is it read-only or full?\n"
  fi
fi

installrslt=$($(dirname $0)/createtmplt.sh -s 2 -d 'SystemVM Template' -n $localfile -t $destdir/ -f $tmplfile -u -v)

if [[ $? -ne 0 ]]; then
  failed 2 "Failed to install system vm template $tmpltimg to $destdir: $installrslt"
fi

if [ "$ext" == "ova" ]
then
  tar xvf $destdir/$localfile -C $destdir &> /dev/null
fi

tmpltfile=$destdir/$localfile
tmpltsize=$(ls -l $tmpltfile | awk -F" " '{print $5}')
if [[ "$ext" == "qcow2" ]]; then
  vrtmpltsize=$($qemuimgcmd info $tmpltfile | grep -i 'virtual size' | sed -ne 's/.*(\([0-9]*\).*/\1/p' | xargs)
else
  vrtmpltsize=$tmpltsize
fi

echo "$ext=true" >> $destdir/template.properties
echo "id=$templateId" >> $destdir/template.properties
echo "public=true" >> $destdir/template.properties
echo "$ext.filename=$localfile" >> $destdir/template.properties
echo "uniquename=routing-$templateId" >> $destdir/template.properties
echo "$ext.virtualsize=$vrtmpltsize" >> $destdir/template.properties
echo "virtualsize=$vrtmpltsize" >> $destdir/template.properties
echo "$ext.size=$tmpltsize" >> $destdir/template.properties

echo "Successfully installed system VM template $tmpltimg and template.properties to $destdir"
