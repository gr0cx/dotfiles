#!/bin/sh

get_vol() {
	amixer get Master | awk -F'[][]' '/Left:|Mono:/ {
        if ($0 ~ /\[off\]/) {
            print "MUT"
        } else {
            print $2
        }
        exit
    }'
}

get_vol

stdbuf -oL alsactl monitor 2>/dev/null | while read -r _; do
	get_vol
done
