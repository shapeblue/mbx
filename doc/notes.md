sshpass example:
sshpass -p 'P@ssword123' ssh -o StrictHostKeyChecking=no root@qa-ry-xs1

get host/ip from virsh via:
ip=$(getent hosts qa-ry-c7kvm1 | awk '{ print $1 }')

virsh list | awk '{ print $2 }' | xargs getent hosts

For KVM:
fix hostname
fix repo URL/yum
rm /etc/default/cloudstack-agent
rm /etc/cloudstack/agent/agent.properties /etc/cloudstack/agent/environment.properties
yum install -y cloudstack-agent

For Vmware:
manually start VC and then add hosts to Cluster
then deploy zone

For XenServer:
on master, run:
xe pool-param-set name-label=XS-Cluster1 uuid=`xe pool-list --minimal`
Deploy Zone, and then run on nodes:
HOSTNAME=$PASS_HOST_NAME_HERE
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
sleep 10
xe host-param-set uuid=$(xe host-list params=uuid|awk {'print $5'} | head -n 1) name-label=$HOSTNAME
echo yes | /opt/xensource/bin/xe-reset-networking --device=eth0 --mode=dhcp
#reboot
xe pool-join master-address=172.20.0.194 master-username=root master-password=P@ssword123


On mgmt server (CentOS7):
# ssh into mgmt server and fix hostname, /etc/hosts etc.
# fix issues with marvin pkgs
yum remove -y python-netaddr
pip uninstall cryptography

# fix cloudsack repo?
yum install -y cloudstack-agent cloudstack-management cloudstack-usage cloudstack-common cloudstack-integration-tests cloudstack-marvin
systemctl enable --now mariadb
cloudstack-setup-databases cloud:cloud@localhost --deploy-as=root: -i $(ip route get 8.8.8.8 | head -1 | awk '{print $7}')
mysql -u root --execute="INSERT INTO cloud.configuration (category, instance, component, name, value)  VALUES ('Advanced', 'DEFAULT', 'management-server', 'integration.api.port', '8096');"
cloudstack-setup-management
# copy marvin cfg here
python /usr/lib/python2.7/site-packages/marvin/deployDataCenter.py -i vmware.marvin.cfg #cfg here
# run tests


vmware 7.0 -> vmxnet3
older can use e1000

