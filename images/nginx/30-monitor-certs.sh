#!/bin/bash
set -x
while :; do
    sleep 1d
    pkill -HUP nginx
done &
disown
