#!/bin/bash

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
