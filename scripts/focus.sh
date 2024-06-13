#!/bin/bash

groupSize=$(hyprctl activewindow -j | jq -r '.grouped | length')

if [[ "$groupSize" == 0 ]]; then
	hyprctl dispatch movefocus $1
else
	if [[ "$1" == "r" ]]; then
	 	hyprctl dispatch changegroupactive f
	elif [[ "$1" == "l" ]]; then
		hyprctl dispatch changegroupactive b
	else
		hyprctl dispatch movefocus $1
	fi
fi

#data=$(hyprctl activewindow -j | jq -r)
#isFloating=$(echo $data | jq -r '.floating')
#if [[ $isFloating ]]; then
#	hyprctl dispatch bringactivetotop
#fi
