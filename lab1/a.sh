#! /usr/bin/env bash

/sbin/ifconfig eth1 10.1.1.20 netmask 255.255.255.0 up
/sbin/ifconfig eth2 10.1.1.30 netmask 255.255.255.0 up
# Check config status
/sbin/ifconfig and netstat –i
# Check interface status
/sbin/ifconfig -a 
# set IP Forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
# bring eth0 down
/sbin/ifconfig eth0 down
# bring eth0 up
/sbin/ifconfig eth0 up

# --------------------

# show routing table
/sbin/route –n
# remove default route
/sbin/route delete default
# Add host route for Rx to the routing table using command
/sbin/route add -host 192.168.98.10 gw 10.1.3.2 dev eth0