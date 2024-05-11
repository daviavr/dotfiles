#!/bin/bash
data=$(hyprctl activewindow -j)
activeWorkspace=$(echo $data | jq -r '.workspace.id | length')

if [[ $activeWorkspace > 90 ]]; then
    NAME=$(echo $data | jq -r '.workspace.name' | awk -F ':' '{print $NF}')
    hyprctl dispatch togglespecialworkspace $NAME
    hyprctl dispatch workspace $1
else
    hyprctl dispatch workspace $1
    
fi
