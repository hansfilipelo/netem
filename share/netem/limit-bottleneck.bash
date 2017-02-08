#!/bin/bash
set -e

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
        #tc qdisc del root dev $interface
    done
}

# Start by restoring qdiscs
restoreQdiscs "netem-veth2" "netem-veth3"

# Buffer size -------------------
bufferMultiplyer=15000
# Calc buffer size as an integer
# The division by 1 is to convert float -> integer
#bufferSize=$(echo "($bufferMultiplyer * $meanDelayDown * 2 * 0.001 * $bandwidthDown * 1000)/1" | bc)
bufferSize="250000"

# Setup the qdiscs -----------------------------------------------------
# Some nesting here but nessecary in order to set ordering correctly.
# Authors note: This looks like shit.
nrQdiscs=0

# Down-link -----------------------------
# Bandwidth
if [ -n "$bandwidthDown" ]; then
    if [ $nrQdiscs -gt 0 ]; then
        tc -s qdisc add dev netem-veth2 parent $nrQdiscs:0 handle $(($nrQdiscs + 1)): netem rate "$bandwidthDown"Mbit limit $bufferSize
    else
        tc -s qdisc replace dev netem-veth2 root handle 1:0 netem rate "$bandwidthDown"Mbit limit $bufferSize limit $bufferSize
    fi
    nrQdiscs=$(($nrQdiscs + 1))
fi


# Delay and loss
tcCommandDelayLoss=""
if [ $nrQdiscs -gt 0 ]; then
    tcCommandDelayLoss="tc -s qdisc add dev netem-veth2 parent $nrQdiscs:0 handle $(($nrQdiscs + 1)):0 netem limit $bufferSize"
else
    tcCommandDelayLoss="tc -s qdisc replace dev netem-veth2 root handle 1:0 netem limit $bufferSize"
fi


if [ -n "$meanDelayDown" ] && [ -n "$delayDeviationDown" ]; then
    tcCommandDelayLoss="$tcCommandDelayLoss delay "$meanDelayDown"ms "$delayDeviationDown"ms distribution normal"
    nrQdiscs=$(($nrQdiscs + 1))

elif [ -n "$meanDelayDown" ]; then
    tcCommandDelayLoss="$tcCommandDelayLoss delay "$meanDelayDown"ms"
    nrQdiscs=$(($nrQdiscs + 1))
elif [ -n "$delayDeviationDown" ] && [ -z "$meanDelayDown"]; then
    echo "ERROR: You can't set a delay deviation without setting a delay!!"
    restoreQdiscs netem-veth2
    exit 11
fi

# Loss
if [ "$lossRateUp" ]; then
    tcCommandDelayLoss="$tcCommandDelayLoss loss "$lossRateDown"% 25%"
fi

eval "$tcCommandDelayLoss"


# Now do uplink! ---------------------------------------------------------------------
nrQdiscs=0
# Bandwidth
if [ -n "$bandwidthUp" ]; then
    if [ $nrQdiscs -gt 0 ]; then
        tc -s qdisc add dev netem-veth3 parent $nrQdiscs:0 handle $(($nrQdiscs + 1)): netem rate "$bandwidthUp"Mbit limit $bufferSize
    else
        tc -s qdisc replace dev netem-veth3 root handle 1:0 netem rate "$bandwidthUp"Mbit limit $bufferSize limit $bufferSize
    fi
    nrQdiscs=$(($nrQdiscs + 1))
fi


# Delay and loss
tcCommandDelayLoss=""
if [ $nrQdiscs -gt 0 ]; then
    tcCommandDelayLoss="tc -s qdisc add dev netem-veth3 parent $nrQdiscs:0 handle $(($nrQdiscs + 1)):0 netem limit $bufferSize"
else
    tcCommandDelayLoss="tc -s qdisc replace dev netem-veth3 root handle 1:0 netem limit $bufferSize"
fi


if [ -n "$meanDelayUp" ] && [ -n "$delayDeviationUp" ]; then
    tcCommandDelayLoss="$tcCommandDelayLoss delay "$meanDelayUp"ms "$delayDeviationUp"ms distribution normal"
    nrQdiscs=$(($nrQdiscs + 1))

elif [ -n "$meanDelayUp" ]; then
    tcCommandDelayLoss="$tcCommandDelayLoss delay "$meanDelayUp"ms"
    nrQdiscs=$(($nrQdiscs + 1))
elif [ -n "$delayDeviationUp" ] && [ -z "$meanDelayUp"]; then
    echo "ERROR: You can't set a delay deviation without setting a delay!!"
    restoreQdiscs netem-veth3
    exit 11
fi

# Loss
if [ "$lossRateUp" ]; then
    tcCommandDelayLoss="$tcCommandDelayLoss loss "$lossRateUp"% 25%"
fi

eval "$tcCommandDelayLoss"


# Enforce MTU sized packets only ---------------------------
ethtool --offload netem-veth0 gso off
ethtool --offload netem-veth0 tso off
ethtool --offload netem-veth0 gro off

ethtool --offload netem-veth2 gso off
ethtool --offload netem-veth2 tso off
ethtool --offload netem-veth2 gro off

ethtool --offload netem-veth3 gso off
ethtool --offload netem-veth3 tso off
ethtool --offload netem-veth3 gro off

ip netns exec netem-ns ethtool --offload netem-veth5 gso off
ip netns exec netem-ns ethtool --offload netem-veth5 tso off
ip netns exec netem-ns ethtool --offload netem-veth5 gro off

