#!/usr/bin/env python3

import sys
import os
import time
import pyvirtualdisplay
from selenium import webdriver


with_gui = False
display = ""

if not "--with-gui" in sys.argv:
    display = pyvirtualdisplay.Display(visible=0, size=(1024, 768))
    display.start()

driver = webdriver.Chrome()
driver.get("https://example.com")
time.sleep(5)
driver.quit()

if not "--with-gui" in sys.argv:
    display.stop
