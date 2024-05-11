#!/bin/bash
wallpapersPath="$HOME/Imagens/character-bgs"
allFiles=$(find $wallpapersPath -maxdepth 1 -type f | sort)

#transform the list of files into the array format
IFS=$'\n' arrayOfFiles=( $allFiles )
length=${#arrayOfFiles[@]}

file="/tmp/currentbg"

if [[ $1 == "first" ]]; then
	currentFile=$(find $wallpapersPath -maxdepth 1 -type f | shuf -n 1)
	for (( i=0; i < $length; i++ )); do
		if [[ "${arrayOfFiles[$i]}" == "$currentFile" ]]; then
			echo "$saveContent" > $file
			break
		fi
	done
	pkill swaybg ; swaybg -m fill -i $currentFile &
else
	i=$(cat "$file" | awk '{print $1}')
	
	if [[ $1 == "n" ]]; then
		i=$(( ($i + 1) % $length ))
	else
		i=$(( ($i + ($length-1)) % $length  ))
	fi
		newCurrentFile="${arrayOfFiles[$i]}"
	pid=( $(pidof swaybg) )
	#echo ${pid[-1]}
	swaybg -m fill -i "$newCurrentFile" &
	sleep 0.1 && kill -9 $pid
	echo "$i" > $file
fi

