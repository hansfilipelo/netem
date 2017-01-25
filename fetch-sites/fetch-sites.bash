#!/bin/bash

netemFolder=$(realpath $(dirname $0)/..)
thisFolder=$netemFolder/fetch-sites

# Handle in-arguments
for i in "$@"
do
    case $i in
        # Don't create certs (time consuming)
        --with-gui)
            noGui=false
            shift # past argument=value
            ;;
    esac
done

if [ "$noGui" != false ]; then
    # Use a virtual display buffer
    Xvfb :99 &
    vDispPid=$!
    export DISPLAY=:99
    
    # Save all sites
    for site in $(cat $netemFolder/config/top500sites.txt); do
        echo "Fetching $site..."
        ./automate-save-page-as/save_page_as --browser chromium-browser --destination $netemFolder/webroot $site
    done

    # Stop virtual display
    kill $vDispPid

else
    echo "Fetching $site..."
    for site in $(cat $netemFolder/config/top500sites.txt); do
        ./automate-save-page-as/save_page_as --browser chromium-browser --destination $netemFolder/webroot $site
    done
fi
    
