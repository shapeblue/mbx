vmware 7.0 -> vmxnet3 or e1000e
older can use e1000

# vmware esxi template

enable ssh+shell
disable ipv6
enable vmotion on vmk0
make vmk0 nic to get dhcp as phy nic and vmk0 network/tcp stack to obtain info from dhcp/dns

security setting fort vSwtich0: reject/accept/accept

remove uuid, mac address and IP address from /etc/vmware/esx.conf
remove dhcp leases from /etc/ and /var/lib/dhcp/ paths
esxcfg-advcfg -s 1 /Net/FollowHardwareMac

# Stop hostd
/etc/init.d/hostd stop

# Ensure the new MAC Address is automatically picked up once cloned
localcli system settings advanced set -o /Net/FollowHardwareMac -i 1

# Remove any potential old DHCP leases
rm -f /etc/dhclient*lease

# Ensure new system UUID is generated
sed -i 's#/system/uuid.*##g' /etc/vmware/esx.conf

# VMware 7 only: Remove these lines from /etc/vmware/esx.conf:

/net/vmkernelnic/child[0000]/mac
/net/pnic/child[0001]/mac
/net/pnic/child[0000]/mac

# Unload networking + vmfs3 modules which also contains system UUID mappings
vmkload_mod -u vmfs3
vmkload_mod -u e1000 (before VMware 7)
vmkload_mod -u nvmxnet3 (VMware 7 only)

# vCenter VM

vcenter VM: enable bash and ssh, enable ntp pool, disable password expiry;
on setup use FDQN as vcenterXX.local and add entry in local router (forward and reverse dns)

from the VC.vmx remove:
ethernet0.addressType
uuid.location =
uuid.bios =
ethernet0.generatedAddress =
ethernet0.generatedAddressOffset =

vcenter debug services:
service-control --stop --all
service-control --start --all
