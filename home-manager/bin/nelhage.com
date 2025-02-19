#!/usr/bin/env bash
exec mosh nelhage.com -- tmux new-session -ADs nelhage
