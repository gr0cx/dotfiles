#!/bin/sh

STACK_FILE="/tmp/eww_popups.stack"

if [ -s "$STACK_FILE" ]; then
	LAST_POPUP=$(tail -n 1 "$STACK_FILE")
	sed -i '$d' "$STACK_FILE"

	[ -n "$LAST_POPUP" ] && eww close "$LAST_POPUP" 2>/dev/null
fi

if [ ! -s "$STACK_FILE" ]; then
	pkill -9 -f "sxhkd -c.*sxhkd_popups" 2>/dev/null
	rm -f "$STACK_FILE"
fi
