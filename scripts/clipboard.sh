#!/usr/bin/env bash
#
# Portable clipboard helper for tmux.
#
#   clipboard.sh copy   < stdin    (put stdin on the OS clipboard)
#   clipboard.sh paste  > stdout   (print the OS clipboard)
#
# Detects WSL / macOS / Linux so .tmux.conf does not depend on xclip.
# On WSL it uses PowerShell Set-Clipboard/Get-Clipboard (not clip.exe, whose
# data Windows apps refuse to paste and which Win+V history ignores).

set -u

mode=${1:-}
case "$mode" in
copy | paste) ;;
*)
	echo "usage: $0 copy|paste" >&2
	exit 2
	;;
esac

if grep -qi microsoft /proc/version 2>/dev/null; then # WSL
	if [ "$mode" = copy ]; then
		powershell.exe -NoProfile -Command "Set-Clipboard -Value ([Console]::In.ReadToEnd())"
	else
		powershell.exe -NoProfile -Command Get-Clipboard | sed 's/\r$//'
	fi
elif [ "$(uname -s)" = Darwin ]; then # macOS
	if [ "$mode" = copy ]; then
		pbcopy
	else
		pbpaste
	fi
else # Linux
	if [ "$mode" = copy ]; then
		if command -v wl-copy >/dev/null 2>&1; then
			wl-copy
		elif command -v xclip >/dev/null 2>&1; then
			xclip -i -sel clipboard
		else
			xsel -b -i
		fi
	else
		if command -v wl-paste >/dev/null 2>&1; then
			wl-paste --no-newline
		elif command -v xclip >/dev/null 2>&1; then
			xclip -o -sel clipboard
		else
			xsel -b
		fi
	fi
fi
