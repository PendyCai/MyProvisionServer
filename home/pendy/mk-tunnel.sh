#!/bin/bash

dev=tun0
rip=10.10.6.124
lip=192.168.10.220

ip link set   $dev down 2>/dev/null
ip tunnel del $dev      2>/dev/null

ip tunnel add $dev mode gre remote $rip local $lip ttl 255
ip link set $dev up
ip addr add 10.10.0.20/24 dev $dev



