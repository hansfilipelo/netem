#!/usr/bin/env python3

import sys
import os


withGui = False

if "--with-gui" in sys.argv:
    withGui = True

print(withGui)
