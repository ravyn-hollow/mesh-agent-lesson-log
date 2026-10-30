#!/bin/bash
set -euo pipefail

APP_NAME="${APP_NAME:-Mesh Agent}"
ICON="${ICON:-media-record}"
URGENCY="${URGENCY:-normal}"
TIMEOUT="${TIMEOUT:-3000}"

TITLE="${1:-Notification}"
TEXT="${2:-}"

PLASMA_PID="$(pgrep -n -f 'plasmashell' || true)"

if [ -z "$PLASMA_PID" ]; then
    echo "plasmashell not found" >&2
    exit 1
fi

USER_NAME="$(ps -o user= -p "$PLASMA_PID" | awk '{print $1}')"

DBUS_SESSION_BUS_ADDRESS="$(
    tr '\0' '\n' < "/proc/$PLASMA_PID/environ" |
    grep '^DBUS_SESSION_BUS_ADDRESS=' |
    cut -d= -f2-
)"

DISPLAY="$(
    tr '\0' '\n' < "/proc/$PLASMA_PID/environ" |
    grep '^DISPLAY=' |
    cut -d= -f2-
)"

if [ -z "$DBUS_SESSION_BUS_ADDRESS" ] || [ -z "$DISPLAY" ]; then
    echo "DISPLAY or DBUS_SESSION_BUS_ADDRESS not found for plasmashell pid=$PLASMA_PID" >&2
    exit 1
fi

runuser -u "$USER_NAME" -- \
    env DISPLAY="$DISPLAY" \
        DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
        notify-send \
            -a "$APP_NAME" \
            -u "$URGENCY" \
            -t "$TIMEOUT" \
            -i "$ICON" \
            "$TITLE" "$TEXT"
