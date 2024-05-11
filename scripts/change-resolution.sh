#!/bin/bash
currentResolution=$(hyprctl monitors -j | jq -r '.[0].width')

if [[ $currentResolution == 3440 ]]; then
    hyprctl keyword monitor ",2560x1440@144,auto,1.25"
else
    hyprctl keyword monitor ",3440x1440@144,auto,1.25"
fi
