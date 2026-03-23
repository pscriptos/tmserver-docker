#!/bin/sh

# ============================================================
# XAseco Healthcheck / Watchdog
# ============================================================
# Ueberwacht den XAseco-Prozess und startet ihn automatisch
# neu, wenn er abgestuerzt ist oder die Verbindung zum
# TrackmaniaServer verloren hat (kein Overlay mehr sichtbar).
#
# Pruefungen:
#   1) PID-Check: Ist der XAseco-PHP-Prozess noch aktiv?
#   2) XMLRPC-Check: Kann XAseco den TM-Server noch erreichen?
#      (Erkennt haengende Prozesse, die das Overlay verloren haben)
#
# Umgebungsvariablen:
#   XASECO_HEALTHCHECK          - true/false (Standard: true)
#   XASECO_HEALTHCHECK_INTERVAL - Pruefintervall in Sekunden (Standard: 60)
#   SERVER_XMLRPC_PORT          - XMLRPC-Port des TM-Servers (Standard: 5000)
# ============================================================

XASECO_DIR="/opt/tmserver/xaseco"
HEALTHCHECK_INTERVAL="${XASECO_HEALTHCHECK_INTERVAL:-60}"
XMLRPC_PORT="${SERVER_XMLRPC_PORT:-5000}"
XASECO_PID_FILE="/tmp/xaseco.pid"
RESTART_COUNT=0
MAX_CONSECUTIVE_FAILURES=3
FAILURE_COUNT=0

log() {
    echo "[XAseco-Healthcheck] $(date '+%Y-%m-%d %H:%M:%S') $1"
}

# ============================================================
# XAseco starten und PID speichern
# ============================================================
start_xaseco() {
    cd "$XASECO_DIR"
    php aseco.php TMN </dev/null >>aseco.log 2>&1 &
    NEW_PID=$!
    echo "$NEW_PID" > "$XASECO_PID_FILE"
    cd /opt/tmserver
    RESTART_COUNT=$((RESTART_COUNT + 1))
    FAILURE_COUNT=0
    log "XAseco gestartet (PID: ${NEW_PID}, Neustart #${RESTART_COUNT})"
}

# ============================================================
# Pruefen, ob der XAseco-Prozess noch laeuft
# ============================================================
check_pid() {
    if [ ! -f "$XASECO_PID_FILE" ]; then
        return 1
    fi
    CURRENT_PID=$(cat "$XASECO_PID_FILE")
    if [ -z "$CURRENT_PID" ]; then
        return 1
    fi
    # Pruefen ob der Prozess existiert und ein PHP-Prozess ist
    if kill -0 "$CURRENT_PID" 2>/dev/null; then
        return 0
    fi
    return 1
}

# ============================================================
# XMLRPC-Verbindungscheck: Pruefen, ob der TM-Server noch
# erreichbar ist (erkennt verlorene Verbindungen)
# ============================================================
check_xmlrpc_connection() {
    php -r '
        $port = (int)$argv[1];
        // Testen ob der XMLRPC-Port noch erreichbar ist
        $fp = @fsockopen("127.0.0.1", $port, $errno, $errstr, 5);
        if (!$fp) { exit(1); }

        // Handshake lesen
        $data = @fread($fp, 4);
        if (strlen($data) < 4) { fclose($fp); exit(1); }
        $info = unpack("Vsize", $data);
        $handshake = @fread($fp, $info["size"]);
        if (strpos($handshake, "GBXRemote") === false) { fclose($fp); exit(1); }

        fclose($fp);
        exit(0);
    ' "$XMLRPC_PORT" 2>/dev/null
    return $?
}

# ============================================================
# XAseco-Log auf aktuelle Fehler pruefen
# ============================================================
check_xaseco_log() {
    LOG_FILE="$XASECO_DIR/aseco.log"
    if [ ! -f "$LOG_FILE" ]; then
        return 0
    fi
    # Letzte 20 Zeilen auf fatale Fehler / Verbindungsabbrueche pruefen
    LAST_LINES=$(tail -20 "$LOG_FILE" 2>/dev/null)
    # Typische Fehlermeldungen bei XAseco-Verbindungsverlust
    if echo "$LAST_LINES" | grep -qi "connection refused\|broken pipe\|server not responding\|transport error\|socket error\|fatal error"; then
        return 1
    fi
    return 0
}

# ============================================================
# Hauptschleife: Regelmaeige Ueberwachung
# ============================================================
log "Watchdog gestartet (Intervall: ${HEALTHCHECK_INTERVAL}s, XMLRPC-Port: ${XMLRPC_PORT})"

while true; do
    sleep "$HEALTHCHECK_INTERVAL"

    # Pruefen ob der TM-Server selbst noch laeuft
    if ! check_xmlrpc_connection; then
        log "XMLRPC-Port ${XMLRPC_PORT} nicht erreichbar - TM-Server vermutlich beendet. Watchdog stoppt."
        break
    fi

    NEED_RESTART=false
    REASON=""

    # 1) PID-Check: Prozess noch aktiv?
    if ! check_pid; then
        NEED_RESTART=true
        REASON="Prozess nicht mehr aktiv (PID: $(cat "$XASECO_PID_FILE" 2>/dev/null || echo 'unbekannt'))"
    fi

    # 2) Log-Check: Fatale Fehler erkannt?
    if [ "$NEED_RESTART" = "false" ] && ! check_xaseco_log; then
        FAILURE_COUNT=$((FAILURE_COUNT + 1))
        log "WARNUNG: Fehler im XAseco-Log erkannt (${FAILURE_COUNT}/${MAX_CONSECUTIVE_FAILURES})"
        if [ "$FAILURE_COUNT" -ge "$MAX_CONSECUTIVE_FAILURES" ]; then
            NEED_RESTART=true
            REASON="Wiederholte Fehler im Log (${FAILURE_COUNT}x)"
        fi
    else
        # Kein Fehler -> Zaehler zuruecksetzen (nur wenn PID OK)
        if [ "$NEED_RESTART" = "false" ]; then
            FAILURE_COUNT=0
        fi
    fi

    # Neustart durchfuehren
    if [ "$NEED_RESTART" = "true" ]; then
        log "NEUSTART ERFORDERLICH: ${REASON}"

        # Alten Prozess sicherheitshalber beenden
        OLD_PID=$(cat "$XASECO_PID_FILE" 2>/dev/null)
        if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
            log "Beende haengenden Prozess (PID: ${OLD_PID})..."
            kill "$OLD_PID" 2>/dev/null
            sleep 3
            # Falls noch aktiv: SIGKILL
            if kill -0 "$OLD_PID" 2>/dev/null; then
                kill -9 "$OLD_PID" 2>/dev/null
                sleep 1
            fi
        fi

        # Log rotieren (altes Log sichern fuer Debugging)
        if [ -f "$XASECO_DIR/aseco.log" ]; then
            TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
            cp "$XASECO_DIR/aseco.log" "$XASECO_DIR/aseco_crash_${TIMESTAMP}.log"
            log "Crash-Log gesichert: aseco_crash_${TIMESTAMP}.log"
            # Maximal 5 Crash-Logs aufbewahren
            ls -t "$XASECO_DIR"/aseco_crash_*.log 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null
        fi

        # Kurz warten, damit evtl. Ressourcen freigegeben werden
        sleep 2

        # XAseco neu starten
        start_xaseco
        log "XAseco erfolgreich neugestartet."

        # Nach Neustart etwas laenger warten, damit XAseco sich initialisieren kann
        sleep 10
    fi
done

log "Watchdog beendet."
