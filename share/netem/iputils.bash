#!/bin/bash

ip2int()
{
    local a b c d
    { IFS=. read a b c d; } <<< $1
    echo $(((((((a << 8) | b) << 8) | c) << 8) | d))
}

int2ip()
{
    local ui32=$1; shift
    local ip n
    for n in 1 2 3 4; do
        ip=$((ui32 & 0xff))${ip:+.}$ip
        ui32=$((ui32 >> 8))
    done
    echo $ip
}

netmask()
{
    local mask=$((0xffffffff << (32 - $1))); shift
    int2ip $mask
}


broadcast()
{
    local addr=$(ip2int $1); shift
    local mask=$((0xffffffff << (32 -$1))); shift
    int2ip $((addr | ~mask))
}

network()
{
    local addr=$(ip2int $1); shift
    local mask=$((0xffffffff << (32 -$1))); shift
    int2ip $((addr & mask))
}

beginningOfIp()
{
  thisNetwork=$1
  netmaskBits=$2
  outputString=$thisNetwork
  loopstop=1
  if [ "$netmaskBits" = "24" ]; then
    loopstop=1
    appendString=""
  elif [ "$netmaskBits" = "16" ]; then
    loopstop=2
    appendString=".0"
  elif [ "$netmaskBits" = "8" ]; then
    loopstop=3
    appendString=".0.0"
  fi

  i=0
  while [ $i -lt $loopstop ]; do
    outputString=$(echo $outputString | sed 's/\(.*\)\..*/\1/')
    i=$(($i+1))
  done
  echo "$outputString$appendString"
}

broadcastFromNetworkAndBits()
{
  thisNetwork=$1
  netmaskBits=$2
  outputString=$thisNetwork
  loopstop=1
  if [ "$netmaskBits" = "24" ]; then
    loopstop=1
    appendString=".255"
  elif [ "$netmaskBits" = "16" ]; then
    loopstop=2
    appendString=".255.255"
  elif [ "$netmaskBits" = "8" ]; then
    loopstop=3
    appendString=".255.255.255"
  fi

  i=0
  while [ $i -lt $loopstop ]; do
    outputString=$(echo $outputString | sed 's/\(.*\)\..*/\1/')
    i=$(($i+1))
  done
  echo "$outputString$appendString"
}

netmaskFromBits()
{
  netmaskBits=$1
  if [ "$netmaskBits" = "24" ]; then
    echo "255.255.255.0"
  elif [ "$netmaskBits" = "16" ]; then
    echo "255.255.0.0"
  elif [ "$netmaskBits" = "8" ]; then
    echo "255.0.0.0"
  fi
}
