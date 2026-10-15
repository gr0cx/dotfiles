#!/usr/bin/env bash

# Ruta de la captura procesada
BG_IMG="/tmp/xsecurelock_toxic_bg.png"

# 1. Capturar pantalla actual
if command -v maim &>/dev/null; then
	maim "$BG_IMG"
elif command -v scrot &>/dev/null; then
	scrot "$BG_IMG"
fi

# 2. Procesar fondo con ImageMagick 7 (`magick`) + Inyectar HUD Cyberpunk
if [ -f "$BG_IMG" ]; then
	# Nombre de host seguro sin depender del binario 'hostname'
	HOSTNAME_STR="${HOSTNAME:-$(uname -n 2>/dev/null || echo 'localhost')}"
	USER_STR=$(whoami)
	TIME_STR=$(date +"%H:%M:%S")

	# Detectar dinámicamente la ruta real de la fuente para ImageMagick
	FONT_PATH=$(fc-match -f "%{file}" "Hack Nerd Font" 2>/dev/null)
	[ -z "$FONT_PATH" ] && FONT_PATH="sans-serif"

	magick "$BG_IMG" \
		-level 0%,100%,0.75 \
		-filter Gaussian -resize 20% -define filter:sigma=2.5 -resize 500% \
		-fill "#0a0c0e" -colorize 55% \
		-font "$FONT_PATH" \
		-fill "#00ff66" -pointsize 20 \
		-gravity NorthWest -annotate +60+50 "󰌾 SYSTEM_LOCKED // AUTHORIZATION_REQUIRED" \
		-fill "#5c6b73" -pointsize 13 \
		-gravity NorthWest -annotate +60+85 "HOST: ${HOSTNAME_STR}  |  USER: ${USER_STR}  \vert{}  TIMESTAMP:${TIME_STR}" \
		-stroke "#00ff66" -strokewidth 2 \
		-draw "line 60,110 480,110" \
		-stroke none -fill "#5c6b73" -pointsize 12 \
		-gravity SouthWest -annotate +60+50 "󰞦 PROTOCOL: PAM_AUTH  |  ENCRYPTION: AES-256-GCM  |  STATUS: SECURE" \
		"$BG_IMG"
fi

# --- PERSONALIZACIÓN DE LA CAJA CENTRAL (auth_x11) ---
export XSECURELOCK_FONT="Hack Nerd Font"

export XSECURELOCK_ALLOW_COMPOSITOR=1

# Colores Cyberpunk/Toxic
export XSECURELOCK_COLOR_MUTED_BACKGROUND="#0a0c0e" # Fondo cuando está inactiva ($bg-dark)
export XSECURELOCK_COLOR_MUTED_FOREGROUND="#5c6b73" # Texto tenue ($text-muted)
export XSECURELOCK_COLOR_AUTH_BACKGROUND="#121518"  # Fondo cuando escribes ($bg-surface)
export XSECURELOCK_COLOR_AUTH_FOREGROUND="#00ff66"  # Texto/Asteriscos ($primary)
export XSECURELOCK_COLOR_AUTH_WARNING="#ff2a6d"     # Error / Alerta ($urgent)

# Posicionamiento y Dinámica
export XSECURELOCK_PROMPT_X_OFFSET=0           # Alineado al centro horizontal
export XSECURELOCK_PROMPT_Y_OFFSET=100         # Ligeramente desplazada hacia abajo
export XSECURELOCK_PASSWORD_PROMPT="asterisks" # O "cursor" para estilo consola pura
export XSECURELOCK_WAIT_TIME_MS=4000           # Se oculta a los 4s de inactividad

# Información visible en la caja
export XSECURELOCK_SHOW_HOSTNAME=0
export XSECURELOCK_SHOW_DATETIME=0
export XSECURELOCK_SHOW_USERNAME=1
export XSECURELOCK_SHOW_KEY_LAYOUT=1

# Renderizado mediante mpv sin uso de CPU
export XSECURELOCK_SAVER="saver_mpv"
export XSECURELOCK_LIST_VIDEOS_COMMAND="echo $BG_IMG"

# 3. Lanzar bloqueo
exec xsecurelock
