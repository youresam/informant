#!/bin/bash

# This script acts like a continuous integration client for informant board.
# The latest code is pulled from
# Directions:
#   Run this script normally and the latest code will be synced in ./informant/
#   To set as startup on raspberry pi: run_ci --install

# Spec: Running this file normally copies its directory to tmp and runs from there by
#       using the args: run <origindir>

#fixme: this file keeps getting erased on shutdown and I don't know why. workaround is to run the following cmd on boot
# To reset during testing: git fetch --all && git reset --hard origin/master && chmod +x run_ci.sh

# local vars
localdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" #http://stackoverflow.com/a/246128
changed=0

# Set as startup program on raspberry pi
function install {
    #add line (if not exists) to /etc/xdg/lxsession/LXDE/autostart
    # @/home/pi/board/informant/run_ci.sh
    exit #todo
}

# Remove as startup program on raspberry pi
function uninstall {
    exit #todo
}

function start_informant {
    stop_informant
    echo "starting informant"
    cd ${localdir}/src && python informant.py &
}

function stop_informant {
    echo "stopping informant"
    pkill -f informant.py
}

function query_git {
    echo "querying remote repo"
    cd ${localdir}
    log="`git log --pretty=%H ...refs/heads/master^ | head -n 1`"
    if [ ${#log} -eq 40 ]; then
        [ "$log" = "`git ls-remote origin -h refs/heads/master | cut -f1`" ] && changed=0 || changed=1 #http://stackoverflow.com/a/16920556
        echo "git changed=${changed}"
    fi
    if [ ${changed} -eq 1 ]; then
        update
        run_ci.sh &
        exit 0
    fi
}

function update {
    echo "updating informant"
    cd ${localdir}
    git fetch --all && git reset --hard origin/master && chmod +x run_ci.sh
}

function main {
    query_git
    start_informant
    while true; do
        query_git
        sleep 30
    done
}

main