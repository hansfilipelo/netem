#!/bin/bash

myUser=$1
if [ "$2" = "--with-gui" ]; then
    useGui=true
fi
scriptFolder=$(realpath $(dirname $0))


# Activate virtualenv
source $scriptFolder/../.venv/bin/activate

if [ useGui != true ]; then
    python3 $scriptFolder/browser-runner.py
else
    python3 $scriptFolder/browser-runner.py --with-gui
fi


# Deactivate virtualenv
deactivate
