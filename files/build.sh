#!/usr/bin/env bash
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

set -e

# printenv

export ROOT=/jenkins
cd $ROOT
rm -fr deps/*jar deps/awsapi-lib deps/*.mar NONOSS

if [[ "${PR_ID}" != "" ]]; then
  # Find base branch
  BASE=$(curl https://api.github.com/repos/apache/cloudstack/pulls/$PR_ID | jq -r '.base.ref')
  git checkout ${BASE}
else
  git checkout ${ACS_BRANCH}
fi

# Add github remote
git remote add gh https://github.com/apache/cloudstack.git || true

# Apply PR
if [[ "${PR_ID}" != "" ]]; then
  git config --global user.email "you@example.com"
  git config --global user.name "Your Name"

  sed -i 's/^repoName=.*/repoName=cloudstack/g' tools/git/git-pr
  bash tools/git/git-pr $PR_ID --force
fi

export PATH="$HOME/.jenv/bin:$PATH"
if [[ $DISTRO == "centos6" ]]; then
  export PATH=/opt/rh/maven30/root/usr/bin:/opt/rh/rh-java-common/root/usr/bin:$PATH
fi

eval "$(jenv init -)"
echo $0
cat .java-version || true
jenv shell $(cat .java-version) || true
pwd
whoami
echo $PATH
java -version
javac -version
mvn -version

if [[ "${PR_ID}" != "" ]]; then
  export MINOR=shapeblue${PR_ID}
else
  export MINOR=1
fi

export VERSION=$(grep '<version>' pom.xml | head -2 | tail -1 | cut -d'>' -f2 |cut -d'<' -f1)
export BASE_VERSION=$(echo $VERSION | awk -F . '{print $1"."$2}')
export ACS_BUILD_OPTS="-Dnoredist -Dnonoss"
export MAVEN_OPTS="-Xmx4096m -XX:MaxPermSize=800m"


# Uncomment this if nonoss needs to be rebuilt
# LIBS=NONOSS
# git clone https://github.com/rhtyd/cloudstack-nonoss.git $LIBS --depth=1
# cd $LIBS
# bash -x install-non-oss.sh
# cd $ROOT
# cp $LIBS/vhd-util scripts/vm/hypervisor/xenserver/
# chmod +x scripts/vm/hypervisor/xenserver/vhd-util

# Debian stuff
if [[ $DISTRO == "debian" ]]; then
  rm -frv ../cloudstack*deb
  rm -frv ../cloudstack*.tar.gz
  rm -frv ../cloudstack*.dsc
  rm -frv ../cloudstack*.changes

  echo "cloudstack (${VERSION}) unstable; urgency=low" > $ROOT/newchangelog
	echo "" >> $ROOT/newchangelog
	echo "  * Update the version to ${PACKAGE_VERSION}" >> $ROOT/newchangelog
	echo "" >> $ROOT/newchangelog
	echo " -- Rohit Yadav <rohit.yadav@shapeblue.com>  $(date +'%a, %-d %b %Y %H:%m:%S +0530')" >> $ROOT/newchangelog
	echo "" >> $ROOT/newchangelog
	cat $ROOT/debian/changelog >> $ROOT/newchangelog
	mv $ROOT/newchangelog $ROOT/debian/changelog

	cd $ROOT

	dpkg-buildpackage -uc -us -b

  mv ../cloudstack-*.deb $ROOT

  for pkg in $(ls cloud*.deb);
  do
    cp $pkg /output
  done
else
  # Centos stuff
  cd $ROOT/packaging
  sed -i "s/DEFREL=.*$/DEFREL='-D_rel ${MINOR}'/g" package.sh

  case $DISTRO in
    centos6)
      bash -x package.sh -p noredist -d centos63
      ;;
    centos7)
      bash -x package.sh -p noredist -o rhel7 -d centos7 --release $MINOR
      ;;
    centos8)
      ln -sf /usr/bin/python2 /usr/bin/python
      bash -x package.sh -p noredist -o rhel8 -d centos8 --release $MINOR
      ;;
  esac

  cd $ROOT
	for pkg in $(ls dist/rpmbuild/RPMS/x86_64/);
	do
	  cp dist/rpmbuild/RPMS/x86_64/$pkg /output
	done
fi



