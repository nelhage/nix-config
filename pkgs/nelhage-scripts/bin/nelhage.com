#!/usr/bin/env bash
set -eu
session=${1-nelhage}
exec mosh nelhage.com -- tmux new-session -ADs "${session}"
