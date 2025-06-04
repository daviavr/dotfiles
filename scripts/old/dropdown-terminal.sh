#!/bin/bash
activeWorkspace=$(hyprctl activewindow -j | jq -r '.workspace.id | length')

if [[ $activeWorkspace > 90 ]]; then
    NAME=$(hyprctl activewindow -j | jq -r '.workspace.name' | awk -F ':' '{print $NF}')
    hyprctl dispatch togglespecialworkspace $NAME
fi

pypr toggle stb
