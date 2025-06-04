#!/usr/bin/env bash

PICTURE=/tmp/lockscreen.png
SCREENSHOT="grim $PICTURE"

BLUR="5x4"

$SCREENSHOT
convert $PICTURE -blur $BLUR $PICTURE

pidof swaylock || swaylock -e -f -i $PICTURE
rm $PICTURE
