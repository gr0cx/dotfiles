#!/bin/sh

TARGET=$1
STACK_FILE="/tmp/eww_popups.stack"

touch "$STACK_FILE"

if eww active-windows | grep -q "^${TARGET}:"; then
	eww close "$TARGET" 2>/dev/null
	sed -i "/^${TARGET}$/d" "$STACK_FILE"
else
	eww open "$TARGET"
	sed -i "/^${TARGET}$/d" "$STACK_FILE"
	echo "$TARGET" >>"$STACK_FILE"
fi

if [ -s "$STACK_FILE" ]; then
	if ! pgrep -f "sxhkd -c.*sxhkd_popups" >/dev/null; then
		sxhkd -c "$HOME/.config/eww/sxhkd_popups" &
	fi
else
	pkill -9 -f "sxhkd -c.*sxhkd_popups" 2>/dev/null
	rm -f "$STACK_FILE"
fi
