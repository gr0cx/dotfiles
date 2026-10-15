#!/bin/bash

amixer set Master toggle

state=$(amixer get Master | grep "Mono:" | cut -d'[' -f 4 | cut -d']' -f1)

if [ "$state" == "on" ];then
  amixer set Speaker on
elif [ "$state" == "off" ];then
  amixer set Speaker off
else
  echo "Modify mute_script"
fi
