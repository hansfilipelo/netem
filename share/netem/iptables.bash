#!/bin/bash
network="192.168.100.0"
externalIp=""
internalIp=""

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
      network="${inArg#*=}"
      shift
      ;;
    *)
      echo "$0 : Invalid argument $inArg."
      shift
      ;;
  esac
done

#### INTERFACES ####

externalIf=$(route | grep default | awk '{print $8}')
internalIf=netem-veth0

# --------------------------
# Set up NAT so client can access internet
# Always accept loopback traffic
iptables -A INPUT -i lo -j ACCEPT

# Allow established connections, and those not coming from the outside
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -m state --state NEW -i $internalIf -j ACCEPT
iptables -A INPUT -m state --state NEW -i lo -j ACCEPT
iptables -A FORWARD -i $externalIf -o $internalIf -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow outgoing connections from the LAN side.
iptables -A FORWARD -i $internalIf -o $externalIf -j ACCEPT

# Masquerade - necessary for NAT
iptables -t nat -A POSTROUTING -o $externalIf -j MASQUERADE

# MASQUERADE on packages from internalIf-to-internalIf, nessecary for NAT Loopback
iptables -A POSTROUTING -t nat -s "$network"/24 -d "$network"/24 -p tcp -j MASQUERADE

# Enable routing.
sysctl net.ipv4.ip_forward=1 >> /dev/null
