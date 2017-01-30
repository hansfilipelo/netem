#!/usr/bin/env python3

import sys
import os
import time
import pyvirtualdisplay
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.common.keys import Keys
from selenium import webdriver
import datetime

headless = True
if "--with-gui" in sys.argv:
    headless = False

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
base_url = "https://example.com/"

# Create log file for statistics
now = datetime.datetime.today().isoformat()
statistics_file = open(script_dir +
                       os.path.sep +
                       ".." +
                       os.path.sep +
                       "logs" +
                       os.path.sep +
                       "netem-log-" +
                       now +
                       ".txt", "a")


display = pyvirtualdisplay.Display(visible=0, size=(1024, 768))
if headless:
    display.start()

driver = webdriver.Chrome()

for url in url_list:
    url = url.strip()
    driver.get(base_url + url)

    # Saving some important statistics for use.
    # See
    # http://www.sitepoint.com/profiling-page-loads-with-the-navigation-timing-api/

    # Before connection starts
    connect_start = driver.execute_script(
            "return window.performance.timing.connectStart")
    # Time just after browser receives first byte of response
    response_start = driver.execute_script(
            "return window.performance.timing.responseStart")
    # Time just after browser receives last byte of response
    response_end = driver.execute_script(
            "return window.performance.timing.responseEnd")
    # Time just before dom is set to complete
    dom_complete = driver.execute_script(
            "return window.performance.timing.domComplete")
    # End of page load
    load_event_end = driver.execute_script(
            "return window.performance.timing.loadEventEnd")

    time_to_fetch_resources = response_end - connect_start
    time_to_load_page = load_event_end - connect_start

    # Save some statistics
    print("Time to fetch URL " +
          url +
          ": " +
          str(time_to_fetch_resources) +
          "ms. Total page load time: " +
          str(time_to_load_page) +
          "ms.")
    statistics_line = str(url) +\
        "   " +\
        str(time_to_fetch_resources) +\
        "   " +\
        str(time_to_load_page) +
        "\n"
    statistics_file.write(statistics_line)

    if headless:
        continue
    else:
        input("Press Enter to continue...")

driver.quit()

if headless:
    display.stop
