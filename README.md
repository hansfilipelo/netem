# netem
Tool for spawning a shell with limited network capabilities.

![Netem setup](doc/setup.png?raw=true)

```
Usage:
      netem arguments

--loss-rate-dl= / --loss-rate-ul=
      Specify the loss rate on the down-link/up-link given in percent.

--delay-dl= / --delay-ul
      Specify the delay in ms on the down-link/up-link.

--delay-deviation-dl= / --delay-deviation-ul
      Specify the standard deviation of the delay ms on the down-link/up-link.

--loss-rate-dl= / --loss-rate-ul
      Specify the loss rate on the down-link/up-link.

--bandwidth-dl= / --bandwidth-ul
      Specify the available bandwidth on the down-link/up-link.
```

## Requirements

**Install requirements**

To install some requirements on a Debian based system (Debian 8 "Jessie" / Ubuntu 16.04 or later):

```
sudo apt-get install openvswitch-switch ethtool
```

## Setup

```
git clone https://github.com/hansfilipelo/netem
cd netem
sudo make install
```


