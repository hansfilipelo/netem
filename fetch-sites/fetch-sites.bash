#!/bin/bash

netemFolder=$(realpath $(dirname $0)/..)
thisFolder=$netemFolder/fetch-sites
webRoot=$netemFolder/webroot
urlFile=$netemFolder/config/urls.txt

# Save all sites
echo "Starting!"
echo "----------------"
wget --page-requisites --html-extension --convert-links --span-hosts --no-clobber --tries=2 --timeout=10 --directory-prefix=$webRoot --random-wait --wait 1 --input-file=$urlFile
echo "----------------"
echo ""
