#!/bin/bash
while :; do
    sleep 1d
    pkill -HUP nginx
done &
