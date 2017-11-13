#!/bin/bash
set -e

netemFolder="$(realpath $(dirname $0))/../.."
hostname=$1
lockFile=/tmp/netem.lock
myNetwork="192.168.100"
externalIp=""
internalIp=""
. $netemFolder/share/netem/iputils.bash

# Handle in-arguments -------------
for inArg in "$@"
do
  case $inArg in
    "--internal-ip="*)
      internalIp="${inArg#*=}"
      shift
      ;;
    "--external-ip="*)
      externalIp="${inArg#*=}"
      shift
      ;;
    "--network="*)
      myNetwork="${inArg#*=}"
      shift
      ;;
    *)
      echo "$0 : Invalid argument $inArg."
      shift
      ;;
  esac
done

if [ -z "$internalIp" ]
then
  internalIp="$(beginningOfIp $myNetwork).2"
fi
if [ -z "$externalIp" ]
then
  externalIp="$(beginningOfIp $myNetwork).1"
fi

echo "Netmask: $myNetwork/24" >> $lockFile
echo "Internal IP: $internalIp" >> $lockFile
echo "External IP: $externalIp" >> $lockFile

# Add namespace for the internal
ip netns add netem-ns

# Add three virtual links with two interfaces each
# server -> switch 1
ip link add netem-veth0 type veth peer name netem-veth1
# switch 1 -> switch 2
ip link add netem-veth2 type veth peer name netem-veth3
# switch 2 -> internal
ip link add netem-veth4 type veth peer name netem-veth5

# Create switches
ovs-vsctl add-br switch1
ovs-vsctl add-br switch2

# Attach server interface to server ns
ip link set netem-veth0
# Attach internal interface(s)
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
ifconfig netem-veth0 $externalIp
# Set internal ip
ip netns exec netem-ns ifconfig netem-veth5 $internalIp
ip netns exec netem-ns route add default gw $externalIp
ip netns exec netem-ns ifconfig lo 127.0.0.1
ip netns exec netem-ns ifconfig lo 127.0.1.1

# Route local multicast to the external netem interface
# in order to support multicast streaming from internal IP
route add -net 239.0.0.0/8 dev netem-veth0
