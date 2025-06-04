#!/bin/sh
hyprctl dispatch togglespecialworkspace alacritty && pgrep -f dropin || alacritty --class dropin -T dropin &
