#!/bin/bash

BAT=$(ls /sys/class/power_supply/ | grep -E '^BAT' | head -n 1)

if [ -z "$BAT" ]; then
	echo "No se detectó ninguna batería en el sistema"
	exit 1
fi

BAT_PATH="/sys/class/power_supply/$BAT"
LOW_THRESHOLD=15
FULL_THRESHOLD=100
NOTIFIED_LOW=false
NOTIFIED_FULL=false

for _ in $(seq 1 30); do
	gdbus call --session --dest org.freedesktop.DBus \
		--object-path /org/freedesktop/DBus \
		--method org.freedesktop.DBus.NameHasOwner org.freedesktop.Notifications 2>/dev/null |
		grep -q true && break
	sleep 1
done

while true; do
	if [ -f "$BAT_PATH/capacity" ] && [ -f "$BAT_PATH/status" ]; then
		CAPACITY=$(cat "$BAT_PATH/capacity")
		STATUS=$(cat "$BAT_PATH/status")

		if [ "$CAPACITY" -le "$LOW_THRESHOLD" ] && [ "$STATUS" = "Discharging" ]; then
			if [ "$NOTIFIED_LOW" = false ]; then
				if notify-send -u critical -a "Sistema" -i "battery-low" \
					"Batería baja ($CAPACITY%)" \
					"Por favor, conecta el cargador para evitar que el equipo se apague."; then
					NOTIFIED_LOW=true
				fi
			fi
		elif [ "$STATUS" != "Discharging" ] || [ "$CAPACITY" -gt $((LOW_THRESHOLD + 5)) ]; then
			NOTIFIED_LOW=false
		fi

		if [ "$CAPACITY" -ge "$FULL_THRESHOLD" ] && { [ "$STATUS" = "Charging" ] || [ "$STATUS" = "Full" ] || [ "$STATUS" = "Not charging" ]; }; then
			if [ "$NOTIFIED_FULL" = false ]; then
				if notify-send -u normal -a "Sistema" -i "battery-full" \
					"Batería cargada ($CAPACITY%)" \
					"La batería está completamente cargada. Ya puedes desconectar el cargador."; then
					NOTIFIED_FULL=true
				fi
			fi
		elif [ "$STATUS" = "Discharging" ] || [ "$CAPACITY" -lt 95 ]; then
			NOTIFIED_FULL=false
		fi
	fi

	sleep 15
done
