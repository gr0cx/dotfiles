#!/bin/sh

get_net() {
	SSID=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^sí\|^yes' | cut -d: -f2)
	[ -z "$SSID" ] && echo "Disconnected" || echo "$SSID"
}

get_net
nmcli monitor | while read -r _; do
	get_net
done
