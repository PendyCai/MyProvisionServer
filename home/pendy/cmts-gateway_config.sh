#!/bin/bash

if [  $UID -eq 0 ]; then
   echo "ok"
else
   echo "Must run this script by sudo"
   exit 1
fi
echo  "boot " > /tmp/cmts_log.txt

ip -6 addr     del 2001:DA8:8000:D010:0:5EFE:192.168.10.220/64 dev eth2
route -A inet6 del 2001:da8:8000:d010::/64 gw 2001:DA8:8000:D010:0:5EFE:192.168.10.254


ip -6 addr     add 2001:DA8:8000:D010:0:5EFE:192.168.10.220/64 dev eth2
route -A inet6 add 2001:da8:8000:d010::/64 gw 2001:DA8:8000:D010:0:5EFE:192.168.10.254

echo 1 > /proc/sys/net/ipv4/ip_forward 
iptables -F
iptables -F -t nat
iptables -L
iptables -t nat -A POSTROUTING -o eth3 -s 10.10.7.0/24 -j MASQUERADE
iptables -t nat -A POSTROUTING -o eth3 -s 10.10.6.0/24 -j MASQUERADE
iptables -t nat -A POSTROUTING -o eth3 -s 10.10.8.0/24 -j MASQUERADE
iptables -A FORWARD -i eth3 -o eth1 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth2 -s 10.10.7.0/24 -o eth3 -j ACCEPT
iptables -A FORWARD -i eth2 -s 10.10.6.0/24 -o eth3 -j ACCEPT
iptables -A FORWARD -i eth2 -s 10.10.8.0/24 -o eth3 -j ACCEPT

route del default gw 192.168.10.254
route add -net 10.10.4.0 netmask 255.255.252.0 gw 192.168.10.254
route add -net 10.10.8.0 netmask 255.255.255.0 gw 192.168.10.254

/etc/init.d/rfc868_timeserver restart
/etc/init.d/atftpd stop
sleep 5
rm /tmp/tftp.*
/etc/init.d/atftpd start
/etc/init.d/dhcp3-server  restart
/etc/init.d/dhcpv6-server restart


iptables -L -n>> /tmp/cmts_log.txt
iptables -t nat -L -n >> /tmp/cmts_log.txt
ps aux | grep atftp >> /tmp/cmts_log.txt
ps aux | grep dhcp >> /tmp/cmts_log.txt
ps aux | grep rfc868_timeserver >> /tmp/cmts_log.txt

#/home/pendy/workspace/cmts/dhcpv6/sbin/dhcpd -q  -6 -cf /home/pendy/workspace/cmts/dhcpv6//etc/dhcpd.conf eth2 >/dev/null 2>&1  &

# add by liyvhg @2015-09-23 for isc-dhcp-server web config interface
/opt/software/isc-dhcp-test/boa-0.94.14rc21/src/boa &
# end liyvhg

