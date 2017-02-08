#!/bin/bash
set -e

netemFolder="$(realpath $(dirname $0))/../.."
hostname=$1

# Add namespace for the client
ip netns add netem-ns

# Add three virtual links with two interfaces each
# server -> switch 1
ip link add netem-veth0 type veth peer name netem-veth1
# switch 1 -> switch 2
ip link add netem-veth2 type veth peer name netem-veth3
# switch 2 -> client-2
ip link add netem-veth4 type veth peer name netem-veth5

# Create switches
ovs-vsctl add-br switch1
ovs-vsctl add-br switch2

# Attach server interface to server ns
ip link set netem-veth0
# Attach client interface(s)
ip link set netem-veth5 netns netem-ns

# Attach interfaces to switches
ovs-vsctl add-port switch1 netem-veth1
ovs-vsctl add-port switch1 netem-veth2
ovs-vsctl add-port switch2 netem-veth3
ovs-vsctl add-port switch2 netem-veth4

# Up the links
ifconfig netem-veth1 up
ifconfig netem-veth2 up
ifconfig netem-veth3 up
ifconfig netem-veth4 up

# Set server ip
ifconfig netem-veth0 192.168.100.1
# Set client ip
ip netns exec netem-ns ifconfig netem-veth5 192.168.100.2
ip netns exec netem-ns route add default gw 192.168.100.1
ip netns exec netem-ns ifconfig lo 127.0.0.1
ip netns exec netem-ns ifconfig lo 127.0.1.1

# -----------------------------

