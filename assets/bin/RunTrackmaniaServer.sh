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
error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT
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
DEFAULT_CONTROLPANEL="/opt/tmserver/default-controlpanel"

if [ ! -f "$ADMINSERV_DIR/index.php" ]; then
    echo "==> Erster Start erkannt: Kopiere AdminServ-Dateien ins Volume..."
    cp -a "$DEFAULT_CONTROLPANEL"/* "$ADMINSERV_DIR/"
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

    # ============================================================
    # RemoteCP: Automatische Konfiguration
    # ============================================================
    REMOTECP_DIR="$ADMINSERV_DIR/remotecp"
    if [ -d "$REMOTECP_DIR" ]; then
        echo "==> Konfiguriere RemoteCP..."

        # DB-Konfiguration aus Umgebungsvariablen
        REMOTECP_DB_HOST="${REMOTECP_DB_HOST:-}"
        REMOTECP_DB_NAME="${REMOTECP_DB_NAME:-remotecp}"
        REMOTECP_DB_USER="${REMOTECP_DB_USER:-remotecp}"
        REMOTECP_DB_PASSWORD="${REMOTECP_DB_PASSWORD:-}"

        if [ -n "$REMOTECP_DB_HOST" ] && [ -n "$REMOTECP_DB_PASSWORD" ]; then
            DB_ENABLED="true"
            DB_DSN="mysql:dbname=${REMOTECP_DB_NAME};host=${REMOTECP_DB_HOST}"
        else
            DB_ENABLED="false"
            DB_DSN="mysql:dbname=remotecp;host=localhost"
            echo "    HINWEIS: Keine DB-Zugangsdaten gesetzt (REMOTECP_DB_HOST/REMOTECP_DB_PASSWORD)."
            echo "    RemoteCP wird ohne Datenbank konfiguriert. Manuelle Einrichtung moeglich."
        fi

        # servers.xml: Serververbindung und Datenbank automatisch konfigurieren
        SA_PW=$(printf '%s' "${SERVER_SA_PASSWORD:-SuperAdmin}" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
        SAFE_RCP_NAME=$(printf '%s' "${SERVER_NAME:-Trackmania Server}" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
        SAFE_DB_DSN=$(printf '%s' "$DB_DSN" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
        SAFE_DB_USER=$(printf '%s' "$REMOTECP_DB_USER" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
        SAFE_DB_PW=$(printf '%s' "$REMOTECP_DB_PASSWORD" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
        cat > "$REMOTECP_DIR/xml/servers.xml" <<EORCPSERV
<?xml version="1.0" encoding="utf-8"?>
<servers>
	<server>
		<id>1</id>
		<login></login>
		<name>${SAFE_RCP_NAME}</name>
		<settingset></settingset>
		<filepath></filepath>
		<connection>
			<host>127.0.0.1</host>
			<port>${XMLRPC_PORT}</port>
			<password>${SA_PW}</password>
			<communitycode>000000</communitycode>
		</connection>
		<ftp enabled='false'>
			<host>localhost</host>
			<port></port>
			<username>username</username>
			<password>password</password>
			<path>/GameData/Tracks/</path>
		</ftp>
		<sql enabled='${DB_ENABLED}'>
			<dsn>${SAFE_DB_DSN}</dsn>
			<username>${SAFE_DB_USER}</username>
			<password>${SAFE_DB_PW}</password>
		</sql>
		<lists>
			<guestlist>guestlist.txt</guestlist>
			<blacklist>blacklist.txt</blacklist>
		</lists>
	</server>
</servers>
EORCPSERV

        # admins.xml: Admin-Zugang aus SuperAdmin-Passwort konfigurieren
        RCP_PW="${SERVER_SA_PASSWORD:-SuperAdmin}"
        RCP_PW_MD5=$(printf '%s' "$RCP_PW" | md5sum | cut -d' ' -f1)
        cat > "$REMOTECP_DIR/xml/admins.xml" <<EORCPADM
<?xml version="1.0"?>
<admins>
	<admin>
		<id>L1</id>
		<active>true</active>
		<servers>
			<server id='1' group='1' />
		</servers>
		<username>rcplive</username>
		<password>5b8e508f6f4a95bc581a37243d88f07e</password>
		<nocode>false</nocode>
		<tmaccount>false</tmaccount>
		<language>en</language>
		<style>default</style>
	</admin>
	<admin>
		<id>G1</id>
		<active>true</active>
		<servers>
			<server id='1' group='G1' />
		</servers>
		<username>Guest</username>
		<password>adb831a7fdd83dd1e2a309ce7591dff8</password>
		<nocode>false</nocode>
		<tmaccount>false</tmaccount>
		<language>en</language>
		<style>default</style>
	</admin>
	<admin>
		<id>1</id>
		<active>true</active>
		<servers>
			<server id='1' group='1' />
		</servers>
		<username>SuperAdmin</username>
		<password>${RCP_PW_MD5}</password>
		<nocode>false</nocode>
		<tmaccount>false</tmaccount>
		<language>de</language>
		<style>default</style>
	</admin>
</admins>
EORCPADM

        # ============================================================
        # RemoteCP: Datenbank-Initialisierung
        # ============================================================
        if [ "$DB_ENABLED" = "true" ]; then
            echo "    Warte auf MariaDB (${REMOTECP_DB_HOST})..."
            DB_READY=false
            for i in $(seq 1 30); do
                if mysql -h "$REMOTECP_DB_HOST" -u "$REMOTECP_DB_USER" -p"$REMOTECP_DB_PASSWORD" "$REMOTECP_DB_NAME" -e "SELECT 1" > /dev/null 2>&1; then
                    echo "    MariaDB erreichbar."
                    DB_READY=true
                    break
                fi
                echo "    Versuch $i/30 - MariaDB noch nicht bereit, warte 3s..."
                sleep 3
            done

            if [ "$DB_READY" = "true" ]; then
                echo "    Importiere RemoteCP-Datenbankschema..."
                for sqlfile in "$REMOTECP_DIR"/plugins/*/mysql_*.sql "$REMOTECP_DIR"/live/*/mysql_*.sql; do
                    if [ -f "$sqlfile" ]; then
                        echo "      -> $(basename "$sqlfile")"
                        mysql -h "$REMOTECP_DB_HOST" -u "$REMOTECP_DB_USER" -p"$REMOTECP_DB_PASSWORD" "$REMOTECP_DB_NAME" < "$sqlfile"
                    fi
                done

                # Installer-Markierung setzen (ueberspringt den Web-Installer)
                echo "installed" > "$REMOTECP_DIR/cache/installed"
                chown www-data:www-data "$REMOTECP_DIR/cache/installed"
                echo "    RemoteCP-Datenbank erfolgreich initialisiert."
            else
                echo "    WARNUNG: MariaDB nicht erreichbar nach 90s!"
                echo "    RemoteCP-Datenbank muss manuell eingerichtet werden."
                echo "    Installer: http://<host-ip>/remotecp/index.php?page=install"
            fi
        fi

        # Berechtigungen fuer RemoteCP setzen
        chmod -R 777 "$REMOTECP_DIR/cache"
        chmod -R 777 "$REMOTECP_DIR/xml"
        chown -R www-data:www-data "$REMOTECP_DIR/"

        echo "    RemoteCP-Konfiguration abgeschlossen (Port: ${XMLRPC_PORT}, User: SuperAdmin)."
    fi
else
    echo "==> Vorhandene AdminServ-Daten gefunden. Keine Aenderungen."
fi

# ============================================================
# XAseco: First-Run-Logik
# ============================================================
# Beim ersten Start (leeres Volume) werden die XAseco-Dateien
# aus dem Default-Template ins Volume kopiert und die
# Konfiguration aus den Umgebungsvariablen angewendet.
# ============================================================

XASECO_DIR="/opt/tmserver/xaseco"
DEFAULT_XASECO="/opt/tmserver/default-xaseco"
XASECO_ENABLED="${XASECO_ENABLED:-true}"

if [ "$XASECO_ENABLED" = "true" ]; then
    if [ ! -f "$XASECO_DIR/aseco.php" ]; then
        echo "==> Erster Start erkannt: Kopiere XAseco-Dateien ins Volume..."
        cp -a "$DEFAULT_XASECO"/* "$XASECO_DIR/"

        XMLRPC_PORT="${SERVER_XMLRPC_PORT:-5000}"
        XASECO_ADMIN="${XASECO_MASTERADMIN_LOGIN:-}"
        SA_PW_XASECO=$(printf '%s' "${SERVER_SA_PASSWORD:-SuperAdmin}" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')

        # --- config.xml: MasterAdmin und TMServer-Verbindung konfigurieren ---
        if [ -n "$XASECO_ADMIN" ]; then
            SAFE_ADMIN=$(printf '%s' "$XASECO_ADMIN" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
            # MasterAdmin in die masteradmins-Liste einfuegen (nach <masteradmins>-Tag)
            sed -i "/<masteradmins>/a\\
      <tmlogin>${SAFE_ADMIN}</tmlogin> <ipaddress></ipaddress>" "$XASECO_DIR/config.xml"
            echo "    config.xml: MasterAdmin '${XASECO_ADMIN}' gesetzt."
        else
            echo "    HINWEIS: XASECO_MASTERADMIN_LOGIN nicht gesetzt."
            echo "    Bitte manuell in xaseco/config.xml eintragen!"
        fi

        sed -i "s|<password>YOUR_SUPERADMIN_PASSWORD</password>|<password>${SA_PW_XASECO}</password>|" "$XASECO_DIR/config.xml"
        sed -i "s|<port>5000</port>|<port>${XMLRPC_PORT}</port>|" "$XASECO_DIR/config.xml"
        echo "    config.xml: TMServer-Verbindung konfiguriert (Port: ${XMLRPC_PORT})."

        # --- adminops.xml: Admin-Login eintragen ---
        if [ -n "$XASECO_ADMIN" ]; then
            SAFE_ADMIN=$(printf '%s' "$XASECO_ADMIN" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
            sed -i "s|<!-- format:\n.*<tmlogin>YOUR_ADMIN_LOGIN</tmlogin>.*\n.*-->||" "$XASECO_DIR/adminops.xml"
            # Admin in die admins-Liste einfuegen
            sed -i "/<admins>/a\\
                <tmlogin>${SAFE_ADMIN}</tmlogin> <ipaddress></ipaddress>" "$XASECO_DIR/adminops.xml"
            echo "    adminops.xml: Admin '${XASECO_ADMIN}' eingetragen."
        fi

        # --- localdatabase.xml: MySQL-Verbindung konfigurieren ---
        XASECO_DB_HOST="${XASECO_DB_HOST:-mariadb}"
        XASECO_DB_NAME="${XASECO_DB_NAME:-xaseco}"
        XASECO_DB_USER="${XASECO_DB_USER:-xaseco}"
        XASECO_DB_PASSWORD="${XASECO_DB_PASSWORD:-}"

        if [ -n "$XASECO_DB_PASSWORD" ]; then
            SAFE_DB_HOST=$(printf '%s' "$XASECO_DB_HOST" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
            SAFE_DB_USER=$(printf '%s' "$XASECO_DB_USER" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
            SAFE_DB_PW=$(printf '%s' "$XASECO_DB_PASSWORD" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
            SAFE_DB_NAME=$(printf '%s' "$XASECO_DB_NAME" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
            sed -i "s|<mysql_server>localhost</mysql_server>|<mysql_server>${SAFE_DB_HOST}</mysql_server>|" "$XASECO_DIR/localdatabase.xml"
            sed -i "s|<mysql_login>YOUR_MYSQL_LOGIN</mysql_login>|<mysql_login>${SAFE_DB_USER}</mysql_login>|" "$XASECO_DIR/localdatabase.xml"
            sed -i "s|<mysql_password>YOUR_MYSQL_PASSWORD</mysql_password>|<mysql_password>${SAFE_DB_PW}</mysql_password>|" "$XASECO_DIR/localdatabase.xml"
            sed -i "s|<mysql_database>aseco</mysql_database>|<mysql_database>${SAFE_DB_NAME}</mysql_database>|" "$XASECO_DIR/localdatabase.xml"
            echo "    localdatabase.xml: MySQL-Verbindung konfiguriert (Host: ${XASECO_DB_HOST}, DB: ${XASECO_DB_NAME})."
        else
            echo "    WARNUNG: XASECO_DB_PASSWORD nicht gesetzt!"
            echo "    XAseco-Datenbank muss manuell in xaseco/localdatabase.xml konfiguriert werden."
        fi

        # --- dedimania.xml: Server-Account konfigurieren ---
        DEDI_LOGIN="${SERVER_LOGIN:-}"
        DEDI_PASSWORD="${SERVER_LOGIN_PASSWORD:-}"
        DEDI_NATION="${XASECO_DEDIMANIA_NATION:-DEU}"

        if [ -n "$DEDI_LOGIN" ] && [ -n "$DEDI_PASSWORD" ]; then
            SAFE_DEDI_LOGIN=$(printf '%s' "$DEDI_LOGIN" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
            SAFE_DEDI_PW=$(printf '%s' "$DEDI_PASSWORD" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
            SAFE_DEDI_NATION=$(printf '%s' "$DEDI_NATION" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
            sed -i "s|<login>YOUR_SERVER_LOGIN</login>|<login>${SAFE_DEDI_LOGIN}</login>|" "$XASECO_DIR/dedimania.xml"
            sed -i "s|<password>YOUR_SERVER_PASSWORD</password>|<password>${SAFE_DEDI_PW}</password>|" "$XASECO_DIR/dedimania.xml"
            sed -i "s|<nation>YOUR_SERVER_NATION</nation>|<nation>${SAFE_DEDI_NATION}</nation>|" "$XASECO_DIR/dedimania.xml"
            echo "    dedimania.xml: Server-Account konfiguriert (Nation: ${DEDI_NATION})."
        else
            echo "    HINWEIS: SERVER_LOGIN/SERVER_LOGIN_PASSWORD nicht gesetzt."
            echo "    Dedimania wird ohne Account konfiguriert."
        fi

        # --- XAseco-Datenbank: Schema importieren ---
        if [ -n "$XASECO_DB_PASSWORD" ]; then
            echo "    Warte auf MariaDB (${XASECO_DB_HOST}) fuer XAseco-DB..."
            DB_READY=false
            for i in $(seq 1 30); do
                if mysql -h "$XASECO_DB_HOST" -u "$XASECO_DB_USER" -p"$XASECO_DB_PASSWORD" "$XASECO_DB_NAME" -e "SELECT 1" > /dev/null 2>&1; then
                    echo "    MariaDB erreichbar."
                    DB_READY=true
                    break
                fi
                echo "    Versuch $i/30 - MariaDB noch nicht bereit, warte 3s..."
                sleep 3
            done

            if [ "$DB_READY" = "true" ]; then
                echo "    Importiere XAseco-Datenbankschema..."
                for sqlfile in "$XASECO_DIR"/localdb/*.sql; do
                    if [ -f "$sqlfile" ]; then
                        echo "      -> $(basename "$sqlfile")"
                        mysql -h "$XASECO_DB_HOST" -u "$XASECO_DB_USER" -p"$XASECO_DB_PASSWORD" "$XASECO_DB_NAME" < "$sqlfile"
                    fi
                done
                echo "    XAseco-Datenbank erfolgreich initialisiert."
            else
                echo "    WARNUNG: MariaDB nicht erreichbar nach 90s!"
                echo "    XAseco-Datenbankschema muss manuell importiert werden."
            fi
        fi

        echo "    XAseco-Konfiguration abgeschlossen."
    else
        echo "==> Vorhandene XAseco-Daten gefunden. Keine Aenderungen."
    fi
fi

echo "Starting apache server"
service apache2 start

CONFIG="/opt/tmserver/GameData/Config/dedicated_cfg.txt"
GAME_SETTINGS="/opt/tmserver/GameData/Tracks/MatchSettings/custom_game_settings.txt"
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
    cp -a "$DEFAULT_GAMEDATA"/* "$GAMEDATA_DIR/"
    chmod -R 777 "$GAMEDATA_DIR/Config/"
    mkdir -p "$GAMEDATA_DIR/Config/AdminServ/ServerOptions"
    chown -R www-data:www-data "$GAMEDATA_DIR/Config/AdminServ"
    # Tracks-Verzeichnis fuer AdminServ beschreibbar machen (Maps-Upload/Download)
    chown -R www-data:www-data "$GAMEDATA_DIR/Tracks/"
    chmod -R 755 "$GAMEDATA_DIR/Tracks/"
    APPLY_ENV=true
elif [ "$FORCE_CONFIG_UPDATE" = "true" ]; then
    echo "==> FORCE_CONFIG_UPDATE ist aktiv: Umgebungsvariablen werden erneut angewendet..."
    echo "    ACHTUNG: Manuelle Aenderungen an den betroffenen Feldern werden ueberschrieben!"
    # Template neu kopieren, damit alle Platzhalter vorhanden sind
    cp "$DEFAULT_GAMEDATA/Config/dedicated_cfg.txt" "$CONFIG"
    cp "$DEFAULT_GAMEDATA/Tracks/MatchSettings/custom_game_settings.txt" "$GAME_SETTINGS"
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
    sed -i "s|%%SERVER_LADDER_LIMIT_MAX%%|${SERVER_LADDER_LIMIT_MAX:-60000}|g" "$CONFIG"

    # Netzwerk
    sed -i "s|%%SERVER_PORT%%|${SERVER_PORT}|g" "$CONFIG"
    sed -i "s|%%SERVER_P2P_PORT%%|${SERVER_P2P_PORT}|g" "$CONFIG"
    sed -i "s|%%SERVER_XMLRPC_PORT%%|${SERVER_XMLRPC_PORT}|g" "$CONFIG"
    sed -i "s|%%SERVER_UPLOAD_RATE%%|${SERVER_UPLOAD_RATE}|g" "$CONFIG"
    sed -i "s|%%SERVER_DOWNLOAD_RATE%%|${SERVER_DOWNLOAD_RATE}|g" "$CONFIG"

    # Spieleinstellungen (MatchSettings)
    sed -i "s|<allwarmupduration>[^<]*</allwarmupduration>|<allwarmupduration>${ALLWARMUPDURATION:-0}</allwarmupduration>|" "$GAME_SETTINGS"

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
./TrackmaniaServer /dedicated_cfg=dedicated_cfg.txt /game_settings=MatchSettings/custom_game_settings.txt /nodaemon ${LAUNCH_MODE} &
TM_PID=$!
echo "TrackmaniaServer gestartet (PID: ${TM_PID})"

# ============================================================
# XAseco starten (nach TrackmaniaServer)
# ============================================================
if [ "${XASECO_ENABLED:-true}" = "true" ] && [ -f "/opt/tmserver/xaseco/aseco.php" ]; then
    echo "==> Warte auf TrackmaniaServer XMLRPC..."
    XMLRPC_PORT="${SERVER_XMLRPC_PORT:-5000}"
    XMLRPC_READY=false
    for i in $(seq 1 30); do
        if php -r "@fsockopen('127.0.0.1', ${XMLRPC_PORT}, \$e, \$m, 2) ? exit(0) : exit(1);" 2>/dev/null; then
            XMLRPC_READY=true
            break
        fi
        sleep 2
    done

    if [ "$XMLRPC_READY" = "true" ]; then
        echo "==> Starte XAseco..."
        cd /opt/tmserver/xaseco
        php aseco.php TMN </dev/null >>aseco.log 2>&1 &
        XASECO_PID=$!
        echo "    XAseco gestartet (PID: ${XASECO_PID})"
        cd /opt/tmserver
    else
        echo "    WARNUNG: XMLRPC-Port ${XMLRPC_PORT} nicht erreichbar nach 60s!"
        echo "    XAseco wurde NICHT gestartet. Bitte manuell starten."
    fi
else
    if [ "${XASECO_ENABLED:-true}" != "true" ]; then
        echo "==> XAseco ist deaktiviert (XASECO_ENABLED=${XASECO_ENABLED})."
    fi
fi

# Auf TrackmaniaServer warten (Hauptprozess)
wait $TM_PID
