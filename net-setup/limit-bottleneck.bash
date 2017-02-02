!/bin/bash
set -e

# Handle in-arguments -------------

for argument in "$@"
do
    case $argument in
        "--loss-rate-dl="*)
            lossRateDown="${argument#*=}"
            shift
            ;;
        "--delay-dl="*)
            meanDelayDown="${argument#*=}"
            shift
            ;;
        "--delay-deviation-dl="*)
            delayDeviationDown="${argument#*=}"
            shift
            ;;
        "--bandwidth-dl="*)
            bandwidthDown="${argument#*=}"
            shift
            ;;
        "--loss-rate-ul="*)
            lossRateUp="${argument#*=}"
            shift
            ;;
        "--delay-ul="*)
            meanDelayUp="${argument#*=}"
            shift
            ;;
        "--delay-deviation-ul="*)
            delayDeviationUp="${argument#*=}"
            shift
            ;;
        "--bandwidth-ul="*)
            bandwidthDownUp="${argument#*=}"
            shift
            ;;
        *)
            printHelp $0
            shift
            ;;
    esac
done

# Download params -----------------

meanDelayDown=45 # ms
delayDeviationDown=100 # ms
lossRateDown=0.1 # in percent so 50 -> 50% in EACH direction in EACH direction
connBandwidthDown=0.1 # Mbit/s
bufferMultiplyer=15000

# Upload params -------------------

meanDelayUp=45 # ms
delayDeviationUp=10 # ms
lossRate=0.0 # in percent so 50 -> 50% in EACH direction in EACH direction
connBandwidthUp=0.01 # Mbit/s

# ---------------------------------

# Calc buffer size as an integer
# The division by one is to convert float -> integer
bufferSize=$(echo "($bufferMultiplyer * $meanDelayDown * 2 * 0.001 * $connBandwidthDown * 1000)/1" | bc)

# set link conditions for bottleneck link in both directions (qdiscs operate only on output channels).
tc -s qdisc replace dev veth2 root handle 1:0 netem rate "$connBandwidthDown"Mbit limit $bufferSize
tc -s qdisc add dev veth2 parent 1:0 handle 2: netem delay "$meanDelayDown"ms "$delayDeviationDown"ms distribution normal
#tc -s qdisc add dev veth2 parent 2:0 handle 3: netem loss "$lossRateDown"% 25%

tc -s qdisc replace dev veth3 root handle 1:0 netem rate "$connBandwidthUp"Mbit limit $bufferSize
tc -s qdisc add dev veth3 parent 1:0 handle 2: netem delay "$meanDelayUp"ms "$delayDeviationUp"ms distribution normal
#tc -s qdisc add dev veth3 parent 2:0 handle 3: netem loss "$lossRateUp"% 25%


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
