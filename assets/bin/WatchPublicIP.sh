#!/bin/sh
# Überwacht die ausgehende öffentliche IP des Containers und startet tmserver neu,
# wenn sich die IP ändert, damit er sich mit der neuen IP beim Masterserver registriert.

set -e
apk add --no-cache curl docker-cli > /dev/null 2>&1
set +e

INTERVAL="${IP_WATCHER_INTERVAL:-300}"
LAST_IP=""

echo "[ip-watcher] Gestartet. Prüfintervall: ${INTERVAL}s"

while true; do
    CURRENT_IP=$(curl -s --max-time 10 https://api.ipify.org 2>/dev/null)

    if [ -z "$CURRENT_IP" ]; then
        echo "[ip-watcher] Öffentliche IP konnte nicht ermittelt werden. Neuer Versuch in ${INTERVAL}s."
    elif [ "$CURRENT_IP" != "$LAST_IP" ]; then
        if [ -n "$LAST_IP" ]; then
            echo "[ip-watcher] IP geändert: ${LAST_IP} -> ${CURRENT_IP}. Starte tmserver neu..."
            docker restart tmserver
            echo "[ip-watcher] tmserver erfolgreich neu gestartet."
        else
            echo "[ip-watcher] Initiale öffentliche IP: ${CURRENT_IP}"
        fi
        LAST_IP="$CURRENT_IP"
    else
        echo "[ip-watcher] IP-Prüfung OK: ${CURRENT_IP} (unverändert). Nächste Prüfung in ${INTERVAL}s."
    fi

    sleep "$INTERVAL"
done
