PREFIX ?= /usr/local

BINARY_DIR ?= $(PREFIX)/bin/
SHARE_DIR ?= $(PREFIX)/share/netem

.PHONY: uninstall install

install: bin/netem share/netem/configure.bash share/netem/iptables.bash share/netem/limit-bottleneck.bash share/netem/net-setup.bash share/netem/teardown.bash
	install -D $(CURDIR)/bin/netem $(BINARY_DIR)/netem
	install -D $(CURDIR)/share/netem/configure.bash $(SHARE_DIR)/netem/configure.bash
	install -D $(CURDIR)/share/netem/iptables.bash $(SHARE_DIR)/netem/iptables.bash
	install -D $(CURDIR)/share/netem/limit-bottleneck.bash $(SHARE_DIR)/netem/limit-bottleneck.bash
	install -D $(CURDIR)/share/netem/net-setup.bash $(SHARE_DIR)/netem/net-setup.bash
	install -D $(CURDIR)/share/netem/teardown.bash $(SHARE_DIR)/netem/teardown.bash

uninstall:
	rm -f $(BINARY_DIR)/netem
	rm -rf $(SHARE_DIR)/netem
