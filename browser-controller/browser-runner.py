#!/usr/bin/env python3

import sys
import os
import time
import pyvirtualdisplay
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.common.keys import Keys
from selenium import webdriver


with_gui = False
display = ""
url = "https://example.com"

if not "--with-gui" in sys.argv:
    display = pyvirtualdisplay.Display(visible=0, size=(1024, 768))
    display.start()

driver = webdriver.Chrome()
driver.get(url)

# Saving some important statistics for use. See http://www.sitepoint.com/profiling-page-loads-with-the-navigation-timing-api/ for info on how.
# Before connection starts
connect_start = driver.execute_script("return window.performance.timing.connectStart")
# Time just after browser receives first byte of response
response_start = driver.execute_script("return window.performance.timing.responseStart")
# Time just after browser receives last byte of response
response_end = driver.execute_script("return window.performance.timing.responseEnd") 
# Time just before dom is set to complete
dom_complete = driver.execute_script("return window.performance.timing.domComplete")
# End of page load
load_event_end = driver.execute_script("return window.performance.timing.loadEventEnd")

time_to_fetch_resources = response_end - connect_start
time_to_load_page = load_event_end - connect_start

print("Time to fetch URL " + url + ": " + str(time_to_fetch_resources) + "ms. Total page load time: " + str(time_to_load_page) + "ms.")

driver.quit()

if not "--with-gui" in sys.argv:
    display.stop
