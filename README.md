# netem
Source code for master-thesis

## Requirements

**Certificate**

In order to run the tests with QUIC, you need a valid server certificate and private key for a given domain. This is due to how Chromium handles QUIC security.

**Most requirements**

To install some requirements on a Debian based system (Debian 8 "Jessie" / Ubuntu 16.04 or later):

```
sudo apt-get install openvswitch-switch xvfb python3-dev python3-virtualenv python3-pip virtualenv ethtool
pip3 install pipenv
```

**Chromedriver and Caddy is requirements that must be installed separately**

You can get Caddy by running `go get github.com/mholt/caddy/caddy` using Go >=1.7. You can get Chromedriver from https://sites.google.com/a/chromium.org/chromedriver/downloads. Put Chromedriver in path (recommended location is /usr/local/bin).

## Clone

```
git clone --recursive git@github.com:hansfilipelo/netem
cd netem
```

## Websites to load

There's an included script (`fetch-sites/fetch-sites.bash`) that populates the folder "webroot" with pages from Alexa top 500 that loads somewhat okay as static sites. Either run this or put your own site in:

```
"this-folder"/webroot/url
```

Then replace the contents of the file `config/urls.txt` with your own url. For each entry in `urls.txt` netem will load `https://MY_HOSTNAME/url` from the web server.

## Setup

```
pipenv install
# Remember that you need a VALID certificate for the domain
./configure --key-file=path/to/my/key --cert-file=path/to/my/cert --hostname=MY_HOSTNAME
```


