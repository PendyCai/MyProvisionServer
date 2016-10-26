#!/bin/bash

if [ "$UID" != "0" ]; then
    echo execute $0 as root!
    exit 0
fi

if [ `pidof openvpn` ]; then
    echo Stop OpenVpn
    killall openvpn >& /dev/null
    sleep 2
fi

echo Start OpenVpn
openvpn --cd /etc/openvpn/ --config  myopenvpn.conf
if [ `pidof openvpn` ]; then
	echo Success..
else
	echo failed..
fi

gw=`route -n | grep "^0.0.0.0" | awk '{print $2}'`
if [ "$gw" == "" ]; then
    echo Add default gateway for OpenVpn
    route add -net 192.168.11.0/24 gw 192.168.126.2
    route add default gw 10.9.0.1
elif [ "$gw" != "10.9.0.1" ]; then
    echo Fix default gateway for OpenVpn
    route del default gw $gw
    route add -net 192.168.11.0/24 gw 192.168.126.2
    route add default gw 10.9.0.1
else
    echo Default gateway is OK
fi

ifconfig tun11
route -n

#iptables -t nat -I  POSTROUTING 1 -o tun11 -s 10.10.6.51/32 -j MASQUERADE


