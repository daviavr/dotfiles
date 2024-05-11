#!/bin/bash

groupSize=$(hyprctl activewindow -j | jq -r '.grouped | length')

if [[ "$groupSize" == 0 ]]; then
	hyprctl dispatch cyclenext $1
else
	if [[ "$2" == "r" ]]; then
	 	hyprctl dispatch changegroupactive f
	elif [[ "$2" == "l" ]]; then
		hyprctl dispatch changegroupactive b
	else
		hyprctl dispatch movefocus $2
	fi
fi

#data=$(hyprctl activewindow -j | jq -r)
#isFloating=$(echo $data | jq -r '.floating')
#if [[ $isFloating ]]; then
#	hyprctl dispatch bringactivetotop
#fi
