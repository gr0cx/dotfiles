#!/bin/bash

MODE="${1:---select}" # Modes: --select, --full, --window, --save
TMP_IMG=$(mktemp --suffix=.png)
TARGET_IMG="$TMP_IMG"

case "$MODE" in
  --full)
    maim "$TMP_IMG"
    MSG="Pantalla completa copiada al portapapeles"
    ;;
  --window)
    maim -i "$(xdotool getactivewindow 2>/dev/null)" "$TMP_IMG" 2>/dev/null || maim -i "$(bspc query -N -n focused)" "$TMP_IMG"
    MSG="Ventana copiada al portapapeles"
    ;;
  --save)
    screenshot_dir="$HOME/Pictures/Screenshots/"
    mkdir -p "$screenshot_dir"

    screenshot="$screenshot_dir/screenshot-$(date +%Y%m%d_%H%M%S).png"
    maim -s "$screenshot"

    TARGET_IMG="$screenshot"
    MSG="Área guardada en Screenshots y copiada al portapapeles"
    ;;
  --select|*)
    maim -s "$TMP_IMG"
    MSG="Área seleccionada copiada al portapapeles"
    ;;
esac

if [ -s "$TARGET_IMG" ] && file "$TARGET_IMG" | grep -q 'PNG image data'; then
  xclip -selection clipboard -t image/png -i "$TARGET_IMG"
  notify-send -u "normal" -a "Sistema" -i photo "Captura de pantalla" "$MSG"
fi

rm -f "$TMP_IMG"
