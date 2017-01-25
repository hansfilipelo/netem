#!/bin/bash

netemFolder=$(realpath $(dirname $0))/..

# Remove the NICs
ip link del veth1
ip link del veth2
ip link del veth4

# Destroy switches
ovs-vsctl del-br switch1
ovs-vsctl del-br switch2

# Delete namespaces
ip netns delete server-ns
ip netns delete client-ns2

# Restore hosts-file
if [ -f $netemFolder/hosts.tmp ]; then
    cp $netemFolder/hosts.tmp /etc/hosts
else
    echo ""
    echo "Can't find temporary hosts file! Please remove the entry for example.com from /etc/hosts manually!!"
fi


