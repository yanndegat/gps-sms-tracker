#!/usr/bin/env bash

NETIF=${NETIF:="enp0s29u1u2"}

sudo modprobe usbnet
sudo iptables -A FORWARD -i ${NETIF}:  -o enp0s25 -j ACCEPT
sudo iptables -A FORWARD -i enp0s25 -o ${NETIF} -m state --state ESTABLISHED,RELATED \\n         -j ACCEPT
echo 1 | sudo tee -a /proc/sys/net/ipv4/ip_forward
sudo ip addr add 192.168.7.1 dev ${NETIF}
sudo ip route add 192.168.7.0/24 dev ${NETIF}
