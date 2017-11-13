#netem-!/bin/bash

netemFolder="$(realpath $(dirname $0))/../.."
network=""
internalIp=""
externalIp=""

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
iptables -D POSTROUTING -t nat -s "$network"/24 -d "$network"/24 -p tcp -j MASQUERADE

# Disable forwarding
sysctl net.ipv4.ip_forward=0 >> /dev/null
