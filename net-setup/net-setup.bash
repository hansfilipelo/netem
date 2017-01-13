#!/bin/bash

meanDelay=300 # ms
delayDeviation=200 # ms
lossRate=0.3 # in percent so 50 -> 50% in EACH direction in EACH direction
connBandwidth=0.5 # Mbit/s
bufferMultiplyer=15000

# Calc buffer size as an integer
# The division by one is to convert float -> integer
bufferSize=$(echo "($bufferMultiplyer * $meanDelay * 0.001 * $connBandwidth * 1000)/1" | bc)

# Add two namespaces for server and client
ip netns add server-ns
ip netns add client-ns2

# Add three virtual links with two interfaces each
# server -> switch 1 
ip link add veth0 type veth peer name veth1
# switch 1 -> switch 2
ip link add veth2 type veth peer name veth3
# switch 2 -> client-2
ip link add veth4 type veth peer name veth5

# Create switches
ovs-vsctl add-br switch1
ovs-vsctl add-br switch2

# Attach server interface to server ns
ip link set veth0 netns server-ns
# Attach client interface(s)
ip link set veth5 netns client-ns2

# Attach interfaces to switches
ovs-vsctl add-port switch1 veth1
ovs-vsctl add-port switch1 veth2
ovs-vsctl add-port switch2 veth3
ovs-vsctl add-port switch2 veth4

# Up the links
ifconfig veth1 up
ifconfig veth2 up
ifconfig veth3 up
ifconfig veth4 up

# Set server ip
ip netns exec server-ns ifconfig veth0 192.168.100.1
# Set client IP
ip netns exec client-ns2 ifconfig veth5 192.168.100.2

#set link conditions for bottleneck link in both directions (qdiscs operate only on output channels).
tc -s qdisc replace dev veth2 root handle 1:0 netem rate "$connBandwidth"Mbit limit $bufferSize
tc -s qdisc add dev veth2 parent 1:0 handle 2: netem delay "$meanDelay"ms "$delayDeviation"ms distribution normal
tc -s qdisc add dev veth2 parent 2:0 handle 3: netem loss "$lossRate"% 25%

tc -s qdisc replace dev veth3 root handle 1:0 netem rate "$connBandwidth"Mbit limit $bufferSize
tc -s qdisc add dev veth3 parent 1:0 handle 2: netem delay "$meanDelay"ms "$delayDeviation"ms distribution normal
tc -s qdisc add dev veth3 parent 2:0 handle 3: netem loss "$lossRate"% 25%

#enforce MTU sized packets only.
#ip netns exec server-ns ethtool --offload veth0 gso off
#ip netns exec server-ns ethtool --offload veth0 tso off
#ip netns exec server-ns ethtool --offload veth0 gro off
#
#ethtool --offload veth2 gso off
#ethtool --offload veth2 tso off
#ethtool --offload veth2 gro off
#
#ethtool --offload veth3 gso off
#ethtool --offload veth3 tso off
#ethtool --offload veth3 gro off
#
#ip netns exec client-ns2 ethtool --offload veth5 gso off
#ip netns exec client-ns2 ethtool --offload veth5 tso off
#ip netns exec client-ns2 ethtool --offload veth5 gro off
