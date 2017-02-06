#!/usr/bin/env python3

from hostname import hostname as hostname
import sys
import os
import pyvirtualdisplay
import datetime
import URLLoader

headless = True
debug = False
use_quic = False
use_http = False

web_protocol = sys.argv[1]
max_retries = sys.argv[2]
timeout = sys.argv[3]

try:
    max_retries = int(max_retries)
    timeout = int(timeout)
except ValueError as e:
    print("ERROR: Max retries and timeout must be integers!")
    print(str(e))
    sys.exit(14)

if "--with-gui" in sys.argv:
    headless = False
if "--debug" in sys.argv:
    debug = True
    headless = False
if "--quic" == web_protocol:
    use_quic = True
if "--http1" == web_protocol or "--http2" in web_protocol:
    use_http = True

if use_quic == use_http:
    print("Choose ONE web protocol to use, HTTP/2, HTTP/1.1 or QUIC.")
    sys.exit(2)

# File where we can read URLs
script_dir = os.path.dirname(
    os.path.realpath(__file__))
url_file = open(script_dir +
                os.path.sep +
                ".." +
                os.path.sep +
                "config" +
                os.path.sep +
                "urls.txt", "r")
url_list = url_file.readlines()
base_url = hostname

# Create log file for statistics
now = '{0:%Y-%m-%d_%H-%M-%S}'.format(datetime.datetime.today())
statistics_file = script_dir +\
    os.path.sep +\
    ".." +\
    os.path.sep +\
    "logs" +\
    os.path.sep +\
    "netem-log-" +\
    now +\
    ".txt"

# If not debugging, run headless
display = pyvirtualdisplay.Display(visible=0, size=(1024, 768))
if headless:
    display.start()

# Spawn controller thread and wait for finish
myLoader = URLLoader.URLLoader(base_url, url_list, 60, 3, statistics_file, use_quic, headless, debug)
myLoader.start()
myLoader.join()

# Close virtual display
if headless:
    display.stop()
