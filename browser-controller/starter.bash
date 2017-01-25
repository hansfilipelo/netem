#!/bin/bash

if [ "$1" = "--with-gui" ]; then
    useGui=true
fi
netemFolder=$(realpath $(dirname $0))/..


# Activate virtualenv
source $netemFolder/.venv/bin/activate

if [ $useGui != true ]; then
    python3 $netemFolder/browser-controller/browser-runner.py
else
    python3 $netemFolder/browser-controller/browser-runner.py --with-gui
fi

# Deactivate virtualenv
deactivate


