#!/bin/sh

# ============================================================
# PHP-Debug-Modus konfigurieren (per Umgebungsvariable)
# ============================================================
PHP_DISPLAY_ERRORS="${PHP_DISPLAY_ERRORS:-false}"
PHP_INI_DIR=$(find /etc/php -type d -name "conf.d" -path "*/apache2/*" | head -1)

if [ "$PHP_DISPLAY_ERRORS" = "true" ]; then
    echo "==> PHP-Debug-Modus AKTIVIERT (PHP_DISPLAY_ERRORS=true)"
    cat > "$PHP_INI_DIR/99-adminserv-debug.ini" <<EOF
display_errors = On
error_reporting = E_ALL
log_errors = On
error_log = /var/log/php_errors.log
EOF
else
    echo "==> PHP-Debug-Modus deaktiviert"
    cat > "$PHP_INI_DIR/99-adminserv-debug.ini" <<EOF
display_errors = Off
error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT
log_errors = On
error_log = /var/log/php_errors.log
EOF
fi

# ============================================================
# AdminServ: First-Run-Logik
# ============================================================
# Beim ersten Start (leeres Volume) werden die AdminServ-Dateien
# aus dem Default-Template ins Volume kopiert.
# Bei weiteren Starts bleiben vorhandene Daten (Passwort,
# Server-Eintraege, etc.) erhalten.
# ============================================================

ADMINSERV_DIR="/var/www/html"
DEFAULT_ADMINSERV="/opt/tmserver/default-adminserv"

if [ ! -f "$ADMINSERV_DIR/index.php" ]; then
    echo "==> Erster Start erkannt: Kopiere AdminServ-Dateien ins Volume..."
    cp -r "$DEFAULT_ADMINSERV"/* "$ADMINSERV_DIR/"
    chmod -R 777 "$ADMINSERV_DIR/logs/"
    chmod 666 "$ADMINSERV_DIR/config/adminlevel.cfg.php"
    chmod 666 "$ADMINSERV_DIR/config/servers.cfg.php"
    chmod 666 "$ADMINSERV_DIR/config/adminserv.cfg.php"
    chown -R www-data:www-data "$ADMINSERV_DIR/"

    # AdminServ-Server-Eintrag automatisch konfigurieren
    XMLRPC_PORT="${SERVER_XMLRPC_PORT:-5000}"
    # Servernamen fuer PHP-Single-Quotes escapen
    SAFE_NAME=$(printf '%s' "${SERVER_NAME:-Trackmania Server}" | sed "s/'/\\\\'/g")
    # ds_pw: Passwort fuer DisplayServ (Serverstatusanzeige auf der Login-Seite)
    DS_PW=$(printf '%s' "${SERVER_USER_PASSWORD:-User}" | sed "s/'/\\\\'/g")
    cat > "$ADMINSERV_DIR/config/servers.cfg.php" <<EOPHP
<?php
class ServerConfig {
    public static \$SERVERS = array(
        '${SAFE_NAME}' => array(
            'address'       => '127.0.0.1',
            'port'          => ${XMLRPC_PORT},
            'mapsbasepath'  => '',
            'matchsettings' => 'MatchSettings/',
            'adminlevel'    => array('SuperAdmin' => 'all', 'Admin' => 'all', 'User' => 'all'),
            'ds_pw'         => '${DS_PW}'
        ),
    );
}
?>
EOPHP
    chmod 666 "$ADMINSERV_DIR/config/servers.cfg.php"
    chown www-data:www-data "$ADMINSERV_DIR/config/servers.cfg.php"
    echo "    AdminServ-Server-Eintrag automatisch konfiguriert (Port: ${XMLRPC_PORT})."

    echo "    AdminServ-Dateien erfolgreich kopiert."
else
    echo "==> Vorhandene AdminServ-Daten gefunden. Keine Aenderungen."
fi

echo "Starting apache server"
service apache2 start

CONFIG="/opt/tmserver/GameData/Config/dedicated_cfg.txt"
GAMEDATA_DIR="/opt/tmserver/GameData"
DEFAULT_GAMEDATA="/opt/tmserver/default-gamedata"

# ============================================================
# Persistente GameData: First-Run-Logik
# ============================================================
# Beim ersten Start (leeres Volume) wird das gesamte GameData-
# Verzeichnis aus dem Default-Template ins Volume kopiert und
# die Umgebungsvariablen auf die Config angewendet.
# Bei weiteren Starts wird die vorhandene Konfiguration beibehalten,
# damit manuelle Aenderungen nicht ueberschrieben werden.
# Mit FORCE_CONFIG_UPDATE=true kann ein erneutes Anwenden erzwungen werden.
# ============================================================

FORCE_CONFIG_UPDATE="${FORCE_CONFIG_UPDATE:-false}"

if [ ! -f "$CONFIG" ]; then
    echo "==> Erster Start erkannt: Kopiere Default-GameData ins Volume..."
    cp -r "$DEFAULT_GAMEDATA"/* "$GAMEDATA_DIR/"
    chmod -R 777 "$GAMEDATA_DIR/Config/"
    mkdir -p "$GAMEDATA_DIR/Config/AdminServ/ServerOptions"
    chown -R www-data:www-data "$GAMEDATA_DIR/Config/AdminServ"
    APPLY_ENV=true
elif [ "$FORCE_CONFIG_UPDATE" = "true" ]; then
    echo "==> FORCE_CONFIG_UPDATE ist aktiv: Umgebungsvariablen werden erneut angewendet..."
    echo "    ACHTUNG: Manuelle Aenderungen an den betroffenen Feldern werden ueberschrieben!"
    # Template neu kopieren, damit alle Platzhalter vorhanden sind
    cp "$DEFAULT_GAMEDATA/Config/dedicated_cfg.txt" "$CONFIG"
    APPLY_ENV=true
else
    echo "==> Vorhandene Konfiguration gefunden. Umgebungsvariablen werden NICHT angewendet."
    echo "    Zum erneuten Anwenden: FORCE_CONFIG_UPDATE=true setzen."
    APPLY_ENV=false
fi

# ============================================================
# Platzhalter in dedicated_cfg.txt durch Umgebungsvariablen ersetzen
# ============================================================
if [ "$APPLY_ENV" = "true" ]; then
    echo "Ersetze Platzhalter in dedicated_cfg.txt mit Umgebungsvariablen..."

    # Authentifizierung
    sed -i "s|%%SERVER_SA_PASSWORD%%|${SERVER_SA_PASSWORD}|g" "$CONFIG"
    sed -i "s|%%SERVER_ADM_PASSWORD%%|${SERVER_ADM_PASSWORD}|g" "$CONFIG"
    sed -i "s|%%SERVER_USER_PASSWORD%%|${SERVER_USER_PASSWORD}|g" "$CONFIG"

    # Masterserver-Account
    sed -i "s|%%SERVER_LOGIN%%|${SERVER_LOGIN}|g" "$CONFIG"
    sed -i "s|%%SERVER_LOGIN_PASSWORD%%|${SERVER_LOGIN_PASSWORD}|g" "$CONFIG"
    sed -i "s|%%SERVER_VALIDATION_KEY%%|${SERVER_VALIDATION_KEY}|g" "$CONFIG"

    # Server-Optionen
    sed -i "s|%%SERVER_NAME%%|${SERVER_NAME}|g" "$CONFIG"
    sed -i "s|%%SERVER_DESC%%|${SERVER_DESC}|g" "$CONFIG"
    sed -i "s|%%SERVER_HIDE%%|${SERVER_HIDE}|g" "$CONFIG"
    sed -i "s|%%SERVER_MAX_PLAYERS%%|${SERVER_MAX_PLAYERS}|g" "$CONFIG"
    sed -i "s|%%SERVER_PASSWORD%%|${SERVER_PASSWORD}|g" "$CONFIG"
    sed -i "s|%%SERVER_MAX_SPECTATORS%%|${SERVER_MAX_SPECTATORS}|g" "$CONFIG"
    sed -i "s|%%SERVER_SPEC_PASSWORD%%|${SERVER_SPEC_PASSWORD}|g" "$CONFIG"
    sed -i "s|%%SERVER_LADDER_MODE%%|${SERVER_LADDER_MODE}|g" "$CONFIG"

    # Netzwerk
    sed -i "s|%%SERVER_PORT%%|${SERVER_PORT}|g" "$CONFIG"
    sed -i "s|%%SERVER_P2P_PORT%%|${SERVER_P2P_PORT}|g" "$CONFIG"
    sed -i "s|%%SERVER_XMLRPC_PORT%%|${SERVER_XMLRPC_PORT}|g" "$CONFIG"
    sed -i "s|%%SERVER_UPLOAD_RATE%%|${SERVER_UPLOAD_RATE}|g" "$CONFIG"
    sed -i "s|%%SERVER_DOWNLOAD_RATE%%|${SERVER_DOWNLOAD_RATE}|g" "$CONFIG"

    echo "Platzhalter erfolgreich ersetzt."
fi

# Bestimme Server-Modus (Standard: internet)
SERVER_MODE="${SERVER_MODE:-internet}"

if [ "$SERVER_MODE" = "internet" ]; then
    echo "Configuring Internet-Dedicated mode"
    if [ -z "$SERVER_LOGIN" ] || [ -z "$SERVER_VALIDATION_KEY" ]; then
        echo "ERROR: SERVER_LOGIN and SERVER_VALIDATION_KEY are required for Internet-Dedicated mode."
        echo "Set SERVER_MODE=lan to start in LAN mode, or provide the required variables."
        exit 1
    fi
    LAUNCH_MODE="/internet"
else
    echo "Configuring LAN-Dedicated mode"
    LAUNCH_MODE="/lan"
fi

echo "Server config dedicated_cfg.txt is"
cat "$CONFIG"

echo "Launching Server in ${SERVER_MODE} mode"
exec ./TrackmaniaServer /dedicated_cfg=dedicated_cfg.txt /game_settings=MatchSettings/custom_game_settings.txt /nodaemon ${LAUNCH_MODE}
