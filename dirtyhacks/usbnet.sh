#!/usr/bin/env bash

NETIF=${NETIF:="enp0s26u1u2"}
IP=${IP:="192.168.2.1/24"}
OUTIF=${OUTIF:=enp0s25}

modprobe usbnet
iptables -t nat -A POSTROUTING -o "${OUTIF}" -j MASQUERADE
iptables -A INPUT -i "${OUTIF}"  -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i "${NETIF}" -j ACCEPT

echo 1 | tee -a /proc/sys/net/ipv4/ip_forward
ip addr add "${IP}" dev "${NETIF}"
