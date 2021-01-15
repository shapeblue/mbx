OVPN_DATA="/export/monkeybox/vpn/ovpn-data"
SERVER="192.168.1.100"

if [ -z $(ls -A $OVPN_DATA) ]; then
  docker pull kylemanna/openvpn
  # Generate Data
  docker run -v $OVPN_DATA:/etc/openvpn --rm kylemanna/openvpn ovpn_genconfig -u udp://$SERVER
  docker run -v $OVPN_DATA:/etc/openvpn --rm -it kylemanna/openvpn ovpn_initpki
fi

# Start server
docker run -v $OVPN_DATA:/etc/openvpn -d -p 1194:1194/udp --cap-add=NET_ADMIN kylemanna/openvpn

# Create user
# docker run -v $OVPN_DATA:/etc/openvpn --rm -it kylemanna/openvpn easyrsa build-client-full rohit-hp nopass
# docker run -v $OVPN_DATA:/etc/openvpn --rm kylemanna/openvpn ovpn_getclient rohit-hp > rohit-hp.ovpn
