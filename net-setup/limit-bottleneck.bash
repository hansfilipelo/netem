#!/bin/bash
# set -e

# Handle in-arguments -------------
for inArg in "$@"
do
    case $inArg in
        "--loss-rate-dl="*)
            lossRateDown="${inArg#*=}"
            shift
            ;;
        "--delay-dl="*)
            meanDelayDown="${inArg#*=}"
            shift
            ;;
        "--delay-deviation-dl="*)
            delayDeviationDown="${inArg#*=}"
            shift
            ;;
        "--bandwidth-dl="*)
            bandwidthDown="${inArg#*=}"
            shift
            ;;
        "--loss-rate-ul="*)
            lossRateUp="${inArg#*=}"
            shift
            ;;
        "--delay-ul="*)
            meanDelayUp="${inArg#*=}"
            shift
            ;;
        "--delay-deviation-ul="*)
            delayDeviationUp="${inArg#*=}"
            shift
            ;;
        "--bandwidth-ul="*)
            bandwidthUp="${inArg#*=}"
            shift
            ;;
        *)
            echo "$0 : Invalid argument $inArg."
            shift
            ;;
    esac
done

# Used for restoring qdiscs
function restoreQdiscs () {
    for interface in $@; do
        tc qdisc replace dev $interface root fq_codel
    done
}

# Start by restoring qdiscs
restoreQdiscs "veth2" "veth3"

# Buffer size -------------------
bufferMultiplyer=15000
# Calc buffer size as an integer
# The division by 1 is to convert float -> integer
bufferSize=$(echo "($bufferMultiplyer * $meanDelayDown * 2 * 0.001 * $bandwidthDown * 1000)/1" | bc)


# Setup the qdiscs -----------------------------------------------------
# Some nesting here but nessecary in order to set ordering correctly.
# Authors note: This looks like shit.
nrQdiscs=0

# Start with down-link -----------------------------
# Bandwidth
if [ -n "$bandwidthDown" ]; then
    tc -s qdisc replace dev veth2 root handle 1:0 netem rate "$bandwidthDown"Mbit limit $bufferSize
    nrQdiscs=$(($nrQdiscs + 1))
fi
# If we fail - exit!
if [ $? != 0 ]; then
    echo "Failed to setup bandwidth limit on down-link!"
    restoreQdiscs veth2
    exit 12
fi

# Delay
if [ -n "$meanDelayDown" ] && [ -n "$delayDeviationDown" ]; then
    if [ $nrQdiscs = 1 ]; then
        tc -s qdisc add dev veth2 parent 1:0 handle 2: netem delay "$meanDelayDown"ms "$delayDeviationDown"ms distribution normal
    else
        tc -s qdisc replace dev veth2 root handle 1:0 netem delay "$meanDelayDown"ms "$delayDeviationDown"ms distribution normal
    fi
    nrQdiscs=$(($nrQdiscs + 1))

elif [ -n "$meanDelayDown" ]; then
    if [ $nrQdiscs = 1 ]; then
        tc -s qdisc add dev veth2 parent 1:0 handle 2: netem delay "$meanDelayDown"ms
    else
        tc -s qdisc replace dev veth2 root handle 1:0 netem delay "$meanDelayDown"ms
    fi
    nrQdiscs=$(($nrQdiscs + 1))
elif [ -n "$delayDeviationDown" ] && [ -z "$meanDelayDown"]; then
    echo "ERROR: You can't set a delay deviation without setting a delay!!"
    restoreQdiscs veth2
    exit 11
fi

# If we fail - exit!
if [ $? != 0 ]; then
    echo "Failed to setup bandwidth limit on down-link!"
    restoreQdiscs veth2
    exit 12
fi

# Loss 
if [ "$lossRateDown" ]; then
    if [ $nrQdiscs > 0 ]; then
        tc -s qdisc add dev veth2 parent $nrQdiscs:0 handle $(($nrQdiscs + 1)): netem loss "$lossRateDown"% 25%
    else
        tc -s qdisc replace dev veth2 root handle 1:0 netem loss "$lossRateDown"% 25%
    fi
fi
# If we fail - exit!
if [ $? != 0 ]; then
    echo "Failed to setup loss on down-link!"
    restoreQdiscs veth2
    exit 12
fi

# Now do uplink! ---------------------------------------------------------------------
nrQdiscs=0

# Bandwidth
if [ $bandwidthUp ]; then
    tc -s qdisc replace dev veth3 root handle 1:0 netem rate "$bandwidthUp"Mbit limit $bufferSize
    nrQdiscs=$(($nrQdiscs + 1))
fi
# If we fail - exit!
if [ $? != 0 ]; then
    echo "Failed to setup bandwidth limit on up-link!"
    restoreQdiscs veth3
    exit 12
fi

# Delay
if [ $meanDelayUp ] && [ $delayDeviationUp ]; then
    if [ $nrQdiscs = 1 ]; then
        tc -s qdisc add dev veth3 parent 1:0 handle 2: netem delay "$meanDelayUp"ms "$delayDeviationUp"ms distribution normal
    else
        tc -s qdisc replace dev veth3 root handle 1:0 netem delay "$meanDelayUp"ms "$delayDeviationUp"ms distribution normal
    fi
    nrQdiscs=$(($nrQdiscs + 1))

elif [ $meanDelayUp ]; then
    if [ $nrQdiscs = 1 ]; then
        tc -s qdisc add dev veth3 parent 1:0 handle 2: netem delay "$meanDelayUp"ms
    else
        tc -s qdisc replace dev veth3 root handle 1:0 netem delay "$meanDelayUp"ms
    fi
    nrQdiscs=$(($nrQdiscs + 1))
elif [ -n "$delayDeviationUp" ] && [ -z "$meanDelayUp"]; then
    echo "ERROR: You can't set a delay deviation without setting a delay!"
    restoreQdiscs veth3
    exit 11
else
    continue
fi

# Loss 
if [ "$lossRateUp" ]; then
    if [ $nrQdiscs > 0 ]; then
        tc -s qdisc add dev veth3 parent $nrQdiscs:0 handle $(($nrQdiscs + 1)): netem loss "$lossRateUp"% 25%
    else
        tc -s qdisc replace dev veth3 root handle 1:0 netem loss "$lossRateUp"% 25%
    fi
fi
# If we fail - exit!
if [ $? != 0 ]; then
    echo "Failed to setup loss on up-link!"
    restoreQdiscs veth3
    exit 12
fi

# Enforce MTU sized packets only ---------------------------
ip netns exec server-ns ethtool --offload veth0 gso off
ip netns exec server-ns ethtool --offload veth0 tso off
ip netns exec server-ns ethtool --offload veth0 gro off

ethtool --offload veth2 gso off
ethtool --offload veth2 tso off
ethtool --offload veth2 gro off

ethtool --offload veth3 gso off
ethtool --offload veth3 tso off
ethtool --offload veth3 gro off

ip netns exec client-ns2 ethtool --offload veth5 gso off
ip netns exec client-ns2 ethtool --offload veth5 tso off
ip netns exec client-ns2 ethtool --offload veth5 gro off

