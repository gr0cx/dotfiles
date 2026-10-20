#!/usr/bin/env bash

# ==============================================================================
#   ██████╗ ██████╗  ██████╗  ██████╗██╗  ██╗
#  ██╔════╝ ██╔══██╗██╔═████╗██╔════╝╚██╗██╔╝
#  ██║  ███╗██████╔╝██║██╔██║██║      ╚███╔╝
#  ██║   ██║██╔══██╗████╔╝██║██║      ██╔██╗
#  ╚██████╔╝██║  ██║╚██████╔╝╚██████╗██╔╝ ██╗
#   ╚═════╝  ╚═╝  ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
# ==============================================================================

# ==============================================================================
#  Dotfiles Automator & Installer - Toxic Neon Punk Environment
#  Arch Linux + BSPWM + SXHKD + EWW + LightDM
# ==============================================================================

set -eo pipefail

# --- PATHS AND VARIABLES ---
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$HOME/.config_backup/$TIMESTAMP"
PAUSE_SEC=1

# --- COLORS ---
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

tpunk_logo() {
	echo -e "${CYAN}${BOLD}"
	echo "  ████████╗███╗   ██╗██████╗ ██╗   ██╗███╗   ██╗██╗  ██╗"
	echo "  ╚══██╔══╝████╗  ██║██╔══██╗██║   ██║████╗  ██║██║ ██╔╝"
	echo "     ██║   ██╔██╗ ██║██████╔╝██║   ██║██╔██╗ ██║█████╔╝ "
	echo "     ██║   ██║╚██╗██║██╔═══╝ ██║   ██║██║╚██╗██║██╔═██╗ "
	echo "     ██║   ██║ ╚████║██║     ╚██████╔╝██║ ╚████║██║  ██╗"
	echo "     ╚═╝   ╚═╝  ╚═══╝╚═╝      ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝"
	echo -e "${RESET}"
}

on_interrupt() {
	echo -e "\n\n${YELLOW}[!] ${MSG_CANCELLED:-Instalación cancelada por el usuario. / Installation cancelled by user.}${RESET}"
	exit 130
}

cleanup() {
	local exit_code=$?
	if [ -n "${SUDO_PID:-}" ]; then
		kill "$SUDO_PID" 2>/dev/null || true
	fi
	if [ "$exit_code" -ne 0 ] && [ "$exit_code" -ne 130 ]; then
		echo -e "\n\033[0;31m[!] ${MSG_ABORT_ERR}${exit_code}). Aborted.\033[0m"
	fi
}

trap on_interrupt SIGINT SIGQUIT SIGTERM
trap cleanup EXIT

# ------------------------------------------------------------------------------
# 0. LANGUAGE SELECTION
# ------------------------------------------------------------------------------

clear
tpunk_logo
echo -e "${YELLOW}=== Language Selection / Selección de Idioma ===${RESET}"
echo -e "  1) English (en_US.UTF-8)"
echo -e "  2) Español (es_ES.UTF-8)"
read -rp "$(echo -e "${BOLD}Select your language / Selecciona tu idioma [1/2] (default: 1): ${RESET}")" lang_choice
lang_choice="${lang_choice:-1}"

LOCALE_FILE="$DOTFILES_DIR/locales/$([ "$lang_choice" = "2" ] && echo "es.sh" || echo "en.sh")"

if [ -f "$LOCALE_FILE" ]; then
	source "$LOCALE_FILE"
else
	echo -e "\033[0;31m[ERROR] Locale file not found: $LOCALE_FILE\033[0m"
	exit 1
fi

# ------------------------------------------------------------------------------
# 1. VALIDATIONS AND ERROR HANDLING
# ------------------------------------------------------------------------------

if [ "$EUID" -eq 0 ]; then
	echo -e "\033[0;31m$MSG_ERR_ROOT\033[0m"
	echo -e "$MSG_RUN_NORMAL"
	exit 1
fi

step_pause() {
	sleep "$PAUSE_SEC"
}

clear
tpunk_logo
echo -e "${YELLOW}$MSG_BANNER${RESET}"
echo -e "$MSG_DOTFILES_DIR ${GREEN}$DOTFILES_DIR${RESET}\n"

# User confirmation to proceed
read -rp "$(echo -e "${BOLD}$MSG_PROMPT_INSTALL${RESET}")" confirm
if [[ ! "$confirm" =~ $CONFIRM_REGEX ]]; then
	echo -e "${YELLOW}$MSG_CANCELLED${RESET}"
	exit 0
fi

# Keep sudo session alive
echo -e "\n${CYAN}$MSG_SUDO_REQ${RESET}"
sudo -v || exit 1

CURRENT_TTY="$(tty 2>/dev/null || echo '/dev/tty')"

(while true; do
	sudo -n true 2>/dev/null <"$CURRENT_TTY" || true
	sleep 30
	kill -0 "$$" 2>/dev/null || exit
done) &
SUDO_PID=$!

# ------------------------------------------------------------------------------
# 2. LOCALE GENERATIONS
# ------------------------------------------------------------------------------

echo -e "\n${GREEN}$MSG_STEP1${RESET}"
sudo sed -i "s/#${LOCALE} UTF-8/${LOCALE} UTF-8/" /etc/locale.gen 2>/dev/null || true
sudo locale-gen >/dev/null
echo "LANG=${LOCALE}" | sudo tee /etc/locale.conf >/dev/null
step_pause

# ------------------------------------------------------------------------------
# 3. BACKUP AND SECURE LINK
# ------------------------------------------------------------------------------

safe_copy() {
	local src="$1"
	local dest="$2"

	[ -e "$src" ] || return 0

	mkdir -p "$(dirname "$dest")"

	if [ -e "$dest" ] || [ -L "$dest" ]; then
		echo -e "  ${YELLOW}$MSG_BACKUP${RESET} $dest -> $BACKUP_DIR/"
		mkdir -p "$BACKUP_DIR"
		mv "$dest" "$BACKUP_DIR/" 2>/dev/null || true
	fi

	cp -rf "$src" "$dest"
	echo -e "  ${GREEN}$MSG_OK${RESET} Installed -> $dest"
}

# ------------------------------------------------------------------------------
# 4. PACKAGE INSTALLATION
# ------------------------------------------------------------------------------

echo -e "\n${GREEN}$MSG_STEP2${RESET}"
sudo pacman -Syu --needed --noconfirm \
	base-devel git rust zsh lsd bat fzf starship firefox feh \
	bspwm sxhkd kitty picom rofi python python-dbus python-gobject \
	ttf-hack-nerd lightdm lightdm-gtk-greeter accountsservice \
	maim imagemagick xsecurelock \
	pipewire pipewire-pulse pipewire-alsa wireplumber pamixer alsa-utils playerctl brightnessctl \
	jq socat xclip xorg-setxkbmap mesa mpv libnotify \
	dconf xdg-desktop-portal xdg-desktop-portal-gtk
step_pause

# ------------------------------------------------------------------------------
# 5. PARU INSTALLATION (AUR HELPER)
# ------------------------------------------------------------------------------

if ! command -v paru &>/dev/null || ! paru --version &>/dev/null; then
	echo -e "\n${GREEN}$MSG_STEP3_INSTALL${RESET}"
	rm -rf /tmp/paru
	git clone --depth 1 https://aur.archlinux.org/paru.git /tmp/paru
	(cd /tmp/paru && makepkg -s --noconfirm)
	sudo pacman -U --noconfirm /tmp/paru/*.pkg.tar.zst
	rm -rf /tmp/paru
else
	echo -e "\n${GREEN}$MSG_STEP3_OK${RESET}"
fi
step_pause

# ------------------------------------------------------------------------------
# 6. AUR PACKAGE INSTALLATION
# ------------------------------------------------------------------------------

echo -e "\n${GREEN}$MSG_STEP4${RESET}"
paru -S --needed --noconfirm \
	eww
step_pause

# ------------------------------------------------------------------------------
# 7. ZSH PLUGIN INSTALLATION
# ------------------------------------------------------------------------------

echo -e "\n${GREEN}$MSG_STEP5${RESET}"
ZSH_PLUGINS_DIR="$HOME/.zsh"
mkdir -p "$ZSH_PLUGINS_DIR"

if [ ! -d "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting" ]; then
	git clone --depth 1 "https://github.com/zsh-users/zsh-syntax-highlighting.git" "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting"
fi

if [ ! -d "$ZSH_PLUGINS_DIR/zsh-autosuggestions" ]; then
	git clone --depth 1 "https://github.com/zsh-users/zsh-autosuggestions.git" "$ZSH_PLUGINS_DIR/zsh-autosuggestions"
fi

if [ ! -d "$ZSH_PLUGINS_DIR/zsh-sudo" ]; then
	mkdir -p "$ZSH_PLUGINS_DIR/zsh-sudo"
	curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/plugins/sudo/sudo.plugin.zsh -o "$ZSH_PLUGINS_DIR/zsh-sudo/sudo.plugin.zsh"
fi
step_pause

# ------------------------------------------------------------------------------
# 8. SYMBOLIC LINKING OF DOTFILES
# ------------------------------------------------------------------------------

echo -e "\n${GREEN}$MSG_STEP6${RESET}"

shopt -s dotglob
for file in "$DOTFILES_DIR/home/"*; do
	[ -e "$file" ] || continue
	filename="$(basename "$file")"
	[[ "$filename" == "." || "$filename" == ".." || "$filename" == ".local" ]] && continue
	safe_copy "$file" "$HOME/$filename"
done
shopt -u dotglob

mkdir -p "$HOME/.local/bin"
for script in "$DOTFILES_DIR/home/.local/bin/"*; do
	[ -e "$script" ] || continue
	scriptname="$(basename "$script")"
	safe_copy "$script" "$HOME/.local/bin/$scriptname"
done

mkdir -p "$HOME/.config"
for item in "$DOTFILES_DIR/config/"*; do
	[ -e "$item" ] || continue
	itemname="$(basename "$item")"
	safe_copy "$item" "$HOME/.config/$itemname"
done

safe_copy "$DOTFILES_DIR/assets" "$HOME/Pictures/Wallpapers"
step_pause

read -rp "$(echo -e "${BOLD}$MSG_ROOT_PROMPT${RESET}")" response
if [[ "$response" =~ $CONFIRM_REGEX ]]; then
	echo -e "\n${GREEN}$MSG_STEP6${RESET}"

	echo -e "$MSG_ROOT_DIR"
	sudo mkdir -p /root/.config
	sudo cp -r "$ZSH_PLUGINS_DIR" /root/.zsh

	echo -e "$MSG_ROOT_LINK"
	sudo ln -sfn "$HOME/.zshrc" "/root/.zshrc"
	echo -e "  ${GREEN}$MSG_OK${RESET} /root/.zshrc -> $DOTFILES_DIR/home/.zshrc"
	sudo ln -sfn "$HOME/.config/starship.toml" "/root/.config/starship.toml"
	echo -e "  ${GREEN}$MSG_OK${RESET} /root/.config/starship.toml -> $DOTFILES_DIR/config/starship.toml"

	echo -e "$MSG_ROOT_SHELL"
	sudo chsh -s "$(which zsh)" root || true

	step_pause
fi

# ------------------------------------------------------------------------------
# 9. EXECUTABLE PERMISSIONS
# ------------------------------------------------------------------------------

echo -e "\n${GREEN}$MSG_STEP7${RESET}"
[ -f "$HOME/.config/bspwm/bspwmrc" ] && chmod +x "$HOME/.config/bspwm/bspwmrc"
[ -d "$HOME/.config/eww/scripts" ] && find "$HOME/.config/eww/scripts" -type f -exec chmod +x {} +
[ -d "$HOME/.config/sxhkd/scripts" ] && find "$HOME/.config/sxhkd/scripts" -type f -exec chmod +x {} +
[ -f "$HOME/.config/eww/sxhkd_popups" ] && chmod +x "$HOME/.config/eww/sxhkd_popups"
[ -d "$HOME/.local/bin" ] && find "$HOME/.local/bin" -type f -exec chmod +x {} +

if [ "$SHELL" != "$(which zsh)" ]; then
	echo -e "$MSG_SHELL_CHANGE"
	sudo chsh -s "$(which zsh)" "$USER" || true
fi

FIRST_WALL=$(find "$DOTFILES_DIR/assets" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) | head -n 1)
if [ -n "$FIRST_WALL" ]; then
	feh --bg-fill "$FIRST_WALL" || true
fi
step_pause

# ------------------------------------------------------------------------------
# 10. SYSTEM CONFIGURATION (LIGHTDM AND THEMES)
# ------------------------------------------------------------------------------

echo -e "\n${GREEN}$MSG_STEP8${RESET}"
sudo mkdir -p /usr/share/themes/TNPUNK/gtk-3.0

if [ -d "$DOTFILES_DIR/system/lightdm" ]; then
	sudo cp -f "$DOTFILES_DIR/system/lightdm/lightdm.conf" /etc/lightdm/lightdm.conf 2>/dev/null || true
	sudo cp -f "$DOTFILES_DIR/system/lightdm/lightdm-gtk-greeter.conf" /etc/lightdm/lightdm-gtk-greeter.conf 2>/dev/null || true
fi

if [ -d "$DOTFILES_DIR/system/themes/TNPUNK" ]; then
	sudo cp -rf "$DOTFILES_DIR/system/themes/TNPUNK/"* /usr/share/themes/TNPUNK/
fi

systemctl --user enable pipewire pipewire-pulse wireplumber

sudo systemctl enable accounts-daemon.service
sudo systemctl enable lightdm.service

sudo mkdir -p /etc/X11/xorg.conf.d
sudo tee /etc/X11/xorg.conf.d/00-keyboard.conf >/dev/null <<EOF
Section "InputClass"
    Identifier "system-keyboard"
    MatchIsKeyboard "on"
    Option "XkbLayout" "$KEYBOARD_LAYOUT"
EndSection
EOF

echo -e "\n${CYAN}================================================================${RESET}"
echo -e "${CYAN} $MSG_SUCCESS${RESET}"
if [ -d "$BACKUP_DIR" ]; then
	echo -e "${YELLOW} $MSG_BACKUP_SAVED $BACKUP_DIR${RESET}"
fi
echo -e "${CYAN}================================================================${RESET}"

read -rp "$(echo -e "${BOLD}$MSG_REBOOT${RESET}")" reboot_now
if [[ "$reboot_now" =~ $CONFIRM_REGEX ]]; then
	sudo reboot now
fi
