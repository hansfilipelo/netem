#netem-!/bin/bash

netemFolder="$(realpath $(dirname $0))/../.."

#### INTERFACES ####

external=$(route | grep default | awk '{print $8}')
internal=netem-veth0

# --------------------------------

# Remove the NICs
ip link del netem-veth1
ip link del netem-veth2
ip link del netem-veth4

# Destroy switches
ovs-vsctl del-br switch1
ovs-vsctl del-br switch2

# Delete namespace
ip netns delete netem-ns

# --------------------------
# Destroy iptables rules
iptables -D INPUT -i lo -j ACCEPT
iptables -D INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -D INPUT -m state --state NEW -i $internal -j ACCEPT
iptables -D INPUT -m state --state NEW -i lo -j ACCEPT
iptables -D FORWARD -i $external -o $internal -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -D FORWARD -i $internal -o $external -j ACCEPT
iptables -t nat -D POSTROUTING -o $external -j MASQUERADE
iptables -D POSTROUTING -t nat -s 192.168.100.0/24 -d 192.168.100.0/24 -p tcp -j MASQUERADE

