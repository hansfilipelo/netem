# netem
Tool for spawning a shell with limited network capabilities.

![Netem setup](doc/setup.png?raw=true)


```
Usage:
      netem arguments

--delay-dl= / --delay-ul=
      Specify the average delay in ms on the down-link/up-link.

--delay-deviation-dl= / --delay-deviation-ul=
      Specify the standard deviation of the delay as ms on the down-link/up-link.

--loss-rate-dl= / --loss-rate-ul=
      Specify the loss rate on the down-link/up-link.

--bandwidth-dl= / --bandwidth-ul=
      Specify the available bandwidth on the down-link/up-link.
--internal-ip
      Specify the IP address set within the virtual network namespace. Do not combine with --network but DO combine with --external-ip.

--external-ip=
      Specify the IP address given to the interface within the default system namespace. Do not combine with --network but DO combine with --internal-ip.
```

**Example**

```
$ sudo netem --bandwidth-dl=0.5 --bandwidth-ul=0.2 --delay-dl=100 --delay-ul=100 --delay-deviation-ul=50 --delay-deviation-dl=50
netem-prompt:/my-folder$ RUN_ANY_COMMAND
```

## Requirements

**Install requirements**

To install some requirements on a Debian based system (Debian 8 "Jessie" / Ubuntu 16.04 or later):

```
sudo apt-get install openvswitch-switch ethtool make
```

## Setup

```
git clone https://github.com/hansfilipelo/netem
cd netem
sudo make install
```


