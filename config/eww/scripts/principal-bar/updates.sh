#!/bin/bash

if command -v checkupdates &>/dev/null; then
	pacman_count=$(checkupdates 2>/dev/null | wc -l)
else
	pacman_count="0"
fi

if command -v paru &>/dev/null; then
	aur_count=$(paru -Qua --color never 2>/dev/null | wc -l)
else
	aur_count="0"
fi

total=$((pacman_count + aur_count))
echo "$total"
