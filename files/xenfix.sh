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

service xapi stop
sed -i "/INSTALLATION_UUID/c\INSTALLATION_UUID='$(uuidgen)'" /etc/xensource-inventory
sed -i "/CONTROL_DOMAIN_UUID/c\CONTROL_DOMAIN_UUID='$(uuidgen)'" /etc/xensource-inventory
rm -rf  /var/xapi/state.db
cert="/etc/xensource/xapi-ssl.pem"
cert_backup="${cert}.`date -u +%Y%m%dT%TZ`"
mv -f "${cert}" "${cert_backup}"
/opt/xensource/libexec/generate_ssl_cert "${cert}" `hostname -f`
service xapi start
rm -f /etc/openvswitch/conf.db*
sleep 5
xe host-param-set uuid=$(xe host-list params=uuid|awk {'print $5'} | head -n 1) name-label=$(hostname)
echo yes | /opt/xensource/bin/xe-reset-networking --device=eth0 --mode=dhcp
