#!/usr/bin/env python3

from hostname import hostname as hostname
import sys
import os
import pyvirtualdisplay
import datetime
import URLLoader

headless = True
use_quic = False
use_http = False

if "--with-gui" in sys.argv:
    headless = False
if "--quic" in sys.argv:
    use_quic = True
if "--http1" in sys.argv or "--http2" in sys.argv:
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
myLoader = URLLoader.URLLoader(base_url, url_list, 60, 3, statistics_file, use_quic, headless)
myLoader.start()
myLoader.join()

# Close virtual display
if headless:
    display.stottt
