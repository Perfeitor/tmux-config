#!/usr/bin/env bash
#
# tmux-resurrect "post-restore-all" hook.
#
# Full-screen TUI apps (nvim, opencode, ...) are restored while the pane is
# still at tmux's default size. The SIGWINCH tmux sends when the client
# attaches/switches to the restored window can arrive before the app has
# installed its resize handler, so the app keeps a stale size until the user
# manually resizes the terminal (e.g. Ctrl +/-).
#
# Once restore is done, re-send SIGWINCH to the foreground process group of
# every pane so those apps re-query the terminal size and redraw full-screen.
#
# Configure via:
#   set -g @resurrect-hook-post-restore-all '<this script>'

set -u

resend_winch() {
	tmux list-panes -a -F '#{pane_tty}' 2>/dev/null | while IFS= read -r tty; do
		[ -n "$tty" ] || continue
		# Foreground process group of the pane's tty (the TUI app).
		ps -o tpgid= -t "$tty" 2>/dev/null | tr -d ' ' | sort -u |
			while IFS= read -r pgid; do
				[ -n "$pgid" ] || continue
				[ "$pgid" -gt 1 ] 2>/dev/null || continue
				kill -WINCH -- "-$pgid" 2>/dev/null || true
			done
	done
}

# Detach so we don't block tmux-resurrect's spinner, and give the restored
# apps a moment to finish starting and install their SIGWINCH handlers.
(
	sleep 1
	resend_winch
) >/dev/null 2>&1 &
