#!/bin/sh

get_vol() {
	if pamixer --get-mute | grep -q "true"; then
		echo "MUT"
	else
		echo "$(pamixer --get-volume)%"
	fi
}

get_vol

pactl subscribe 2>/dev/null | while read -r event; do
	if echo "$event" | grep -q "change"; then
		get_vol
	fi
done
