#!/bin/bash
set -e

function printHelp {
	if [ -n "$2" ]; then
		echo "ERROR: $2"
		echo ""
	fi
	echo
	echo "Usage:"
	echo "  $1"
}


netemFolder="$(realpath $(dirname $0))/../.."

# -------------------- Virtual network setup
# Setup network namespaces and infrastructure
echo "Setting up virtual network infrastructure. Will ask for password in order to gain root access."
$netemFolder/share/netem/net-setup.bash
$netemFolder/share/netem/iptables.bash

