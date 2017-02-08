#!/bin/bash

#### INTERFACES ####

external=$(route | grep default | awk '{print $8}')
internal=netem-veth0

# --------------------------
# Set up NAT so client can access internet
# Always accept loopback traffic
iptables -A INPUT -i lo -j ACCEPT

# Allow established connections, and those not coming from the outside
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -m state --state NEW -i $internal -j ACCEPT
iptables -A INPUT -m state --state NEW -i lo -j ACCEPT
iptables -A FORWARD -i $external -o $internal -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow outgoing connections from the LAN side.
iptables -A FORWARD -i $internal -o $external -j ACCEPT

# Masquerade - necessary for NAT
iptables -t nat -A POSTROUTING -o $external -j MASQUERADE

# MASQUERADE on packages from internal-to-internal, nessecary for NAT Loopback
iptables -A POSTROUTING -t nat -s 192.168.100.0/24 -d 192.168.100.0/24 -p tcp -j MASQUERADE

# Enable routing.
echo 1 > /proc/sys/net/ipv4/ip_forward
