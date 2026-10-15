#!/bin/bash

declare -A ROMAN=([I]=1 [II]=2 [III]=3 [IV]=4 [V]=5 [VI]=6 [VII]=7 [VIII]=8 [IX]=9 [X]=10)

parse_report() {
	IFS=':' read -r -a items <<<"$1"

	yuck="(box :class \"workspaces\" :spacing 4 "

	for item in "${items[@]}"; do
		case "$item" in
		O*)
			num="${item#O}"
			dec="${ROMAN[$num]:-$num}"
			yuck+="(eventbox :cursor \"default\" (button :class \"ws-btn ws-focused ws-occupied\" :onclick \"bspc desktop -f ${num}\" \"${dec}\")) "
			;;
		o*)
			num="${item#o}"
			dec="${ROMAN[$num]:-$num}"
			yuck+="(eventbox :cursor \"pointer\" (button :class \"ws-btn ws-occupied\" :onclick \"bspc desktop -f ${num}\" \"${dec}\")) "
			;;
		F*)
			num="${item#F}"
			dec="${ROMAN[$num]:-$num}"
			yuck+="(eventbox :cursor \"default\" (button :class \"ws-btn ws-focused ws-empty\" :onclick \"bspc desktop -f ${num}\" \"${dec}\")) "
			;;
		U*)
			num="${item#U}"
			dec="${ROMAN[$num]:-$num}"
			yuck+="(eventbox :cursor \"default\" (button :class \"ws-btn ws-urgent\" :onclick \"bspc desktop -f ${num}\" \"${dec}\")) "
			;;
		u*)
			num="${item#u}"
			dec="${ROMAN[$num]:-$num}"
			yuck+="(eventbox :cursor \"pointer\" (button :class \"ws-btn ws-urgent\" :onclick \"bspc desktop -f ${num}\" \"${dec}\")) "
			;;
		esac
	done

	yuck+=")"
	echo "$yuck"
}

parse_report "$(bspc wm -g)"

bspc subscribe report | while read -r line; do
	parse_report "$line"
done
