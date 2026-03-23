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
error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT & ~E_WARNING & ~E_NOTICE
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

    # AdminServ-Konfigurationspasswort automatisch sichern
    # OnlineConfig::PASSWORD in adminserv.cfg.php schuetzt die /config-Seite
    # (Server hinzufuegen/aendern/loeschen). Da der Server-Eintrag bereits
    # automatisch konfiguriert wird, ist kein manueller Zugriff noetig.
    # Der Standard-Hash aus dem ZIP wird durch einen zufaelligen ersetzt.
    ADMINSERV_CFG="$ADMINSERV_DIR/config/adminserv.cfg.php"
    if [ -f "$ADMINSERV_CFG" ]; then
        RANDOM_HASH=$(head -c 32 /dev/urandom | md5sum | cut -d' ' -f1)
        sed -i "s|const PASSWORD = '[^']*';|const PASSWORD = '${RANDOM_HASH}';|" "$ADMINSERV_CFG"
        echo "    AdminServ-Konfigurationspasswort automatisch gesichert."
    fi

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

# ============================================================
# XAseco: TeamSpeak3-Plugin Gateway aktualisieren (fuer bestehende Volumes)
# ============================================================
# Das Original-TS3-Gateway ist nicht mehr verfuegbar. Falls die
# teamspeak3.xml fehlt, wird sie aus dem Template kopiert. Falls sie
# bereits existiert (= Nutzer hat eigene TS3-Daten konfiguriert),
# werden NUR die Gateway-URLs (helperURL/logoURL) gezielt aktualisiert.
# Alle anderen Einstellungen (Server, Port, Channel etc.) bleiben
# erhalten. Gleichzeitig wird das Plugin reaktiviert, falls es
# in einer frueheren Version auskommentiert wurde.
# ============================================================
XASECO_DIR_TS3="/opt/tmserver/xaseco"
TS3_XML="$XASECO_DIR_TS3/teamspeak3.xml"
TS3_DEFAULT="/opt/tmserver/default-xaseco/teamspeak3.xml"
TS3_PLUGINS_XML="$XASECO_DIR_TS3/plugins.xml"

# teamspeak3.xml aktualisieren: Kopieren wenn fehlend, Gateway-URLs gezielt patchen
# WICHTIG: Bei bestehender Datei wird NICHT die gesamte Datei ueberschrieben,
# damit benutzerdefinierte Einstellungen (Server, Port, Channel) erhalten bleiben.
# Nur die Gateway-URLs (helperURL/logoURL) werden aktualisiert, falls sie noch
# auf ein altes, nicht mehr erreichbares Gateway zeigen.
if [ -f "$TS3_DEFAULT" ]; then
    if [ ! -f "$TS3_XML" ]; then
        echo "==> TeamSpeak3-Gateway: teamspeak3.xml fehlt, kopiere aus Template..."
        cp "$TS3_DEFAULT" "$TS3_XML"
        echo "    teamspeak3.xml erfolgreich kopiert."
    else
        # Gateway-URLs aus dem Template auslesen
        NEW_HELPER_URL=$(grep -oP '(?<=<helperURL>).*?(?=</helperURL>)' "$TS3_DEFAULT")
        NEW_LOGO_URL=$(grep -oP '(?<=<logoURL>).*?(?=</logoURL>)' "$TS3_DEFAULT")
        # Aktuelle URLs aus der bestehenden Datei auslesen
        CUR_HELPER_URL=$(grep -oP '(?<=<helperURL>).*?(?=</helperURL>)' "$TS3_XML")
        CUR_LOGO_URL=$(grep -oP '(?<=<logoURL>).*?(?=</logoURL>)' "$TS3_XML")
        # Nur patchen, wenn sich die Gateway-URLs unterscheiden
        if [ "$CUR_HELPER_URL" != "$NEW_HELPER_URL" ] || [ "$CUR_LOGO_URL" != "$NEW_LOGO_URL" ]; then
            echo "==> TeamSpeak3-Gateway: Aktualisiere Gateway-URLs (Server-Einstellungen bleiben erhalten)..."
            [ -n "$NEW_HELPER_URL" ] && sed -i "s|<helperURL>.*</helperURL>|<helperURL>${NEW_HELPER_URL}</helperURL>|" "$TS3_XML"
            [ -n "$NEW_LOGO_URL" ] && sed -i "s|<logoURL>.*</logoURL>|<logoURL>${NEW_LOGO_URL}</logoURL>|" "$TS3_XML"
            echo "    Gateway-URLs erfolgreich aktualisiert."
        fi
    fi
fi

# TS3-Plugin reaktivieren, falls es auskommentiert ist
if [ -f "$TS3_PLUGINS_XML" ] && grep -q '<!-- <plugin>plugin\.teamspeak3\.php</plugin> -->' "$TS3_PLUGINS_XML"; then
    echo "==> TeamSpeak3-Plugin: Reaktiviere auskommentiertes Plugin..."
    sed -i 's|<!-- <plugin>plugin\.teamspeak3\.php</plugin> -->|<plugin>plugin.teamspeak3.php</plugin>|' "$TS3_PLUGINS_XML"
    echo "    TeamSpeak3-Plugin erfolgreich aktiviert."
fi

# ============================================================
# RemoteCP: PHP-Warnungen in Plugins fixen (fuer bestehende Volumes)
# ============================================================
# RemoteCP nutzt bare constants (pt_custom, pt_points, ...), die in
# PHP 7.2+ Warnungen ausloesen. Die gepatchte Datei aus dem Image
# wird in das Volume kopiert, falls die alte Version noch vorhanden ist.
# ============================================================
CUSTOMPOINTS_FILE="/var/www/html/remotecp/plugins/CustomPoints/index.php"
CUSTOMPOINTS_DEFAULT="/opt/tmserver/default-controlpanel/remotecp/plugins/CustomPoints/index.php"
if [ -f "$CUSTOMPOINTS_FILE" ] && ! grep -q 'defined.*pt_custom' "$CUSTOMPOINTS_FILE"; then
    echo "==> Patche CustomPoints-Plugin (PHP-Warnungen beheben)..."
    cp "$CUSTOMPOINTS_DEFAULT" "$CUSTOMPOINTS_FILE"
    chown www-data:www-data "$CUSTOMPOINTS_FILE"
    echo "    CustomPoints-Plugin erfolgreich gepatcht."
fi

# ============================================================
# AdminServ: MatchSettings-Bugfixes fuer bestehende Volumes
# ============================================================
# 1) get_matchset_mapimport.php: Berechnet den relativen Pfad aus dem
#    absoluten Dropdown-Pfad statt den URL-Parameter 'd' zu verwenden.
#    Ohne Fix wird z.B. "MatchSettings/" statt "Challenges/Downloaded/"
#    als Praefix in die MatchSettings-Datei geschrieben.
# 2) maps-creatematchset.php: Ueberspringt GetModeScriptInfo fuer
#    TmForever (Methode existiert nur in ManiaPlanet/TM2, Fehler -506).
# ============================================================
ADMINSERV_MAPIMPORT="/var/www/html/resources/ajax/get_matchset_mapimport.php"
ADMINSERV_MAPIMPORT_DEFAULT="/opt/tmserver/default-controlpanel/resources/ajax/get_matchset_mapimport.php"
if [ -f "$ADMINSERV_MAPIMPORT" ] && ! grep -q 'relativePath' "$ADMINSERV_MAPIMPORT"; then
    echo "==> Patche AdminServ: MatchSettings Map-Import (Pfad-Fix)..."
    cp "$ADMINSERV_MAPIMPORT_DEFAULT" "$ADMINSERV_MAPIMPORT"
    chown www-data:www-data "$ADMINSERV_MAPIMPORT"
    echo "    get_matchset_mapimport.php erfolgreich gepatcht."
fi

ADMINSERV_CREATEMATCHSET="/var/www/html/resources/process/maps-creatematchset.php"
ADMINSERV_CREATEMATCHSET_DEFAULT="/opt/tmserver/default-controlpanel/resources/process/maps-creatematchset.php"
if [ -f "$ADMINSERV_CREATEMATCHSET" ] && grep -q "query('GetModeScriptInfo')" "$ADMINSERV_CREATEMATCHSET" && ! grep -q "SERVER_VERSION_NAME != 'TmForever'" "$ADMINSERV_CREATEMATCHSET"; then
    echo "==> Patche AdminServ: GetModeScriptInfo-Fix fuer TmForever..."
    cp "$ADMINSERV_CREATEMATCHSET_DEFAULT" "$ADMINSERV_CREATEMATCHSET"
    chown www-data:www-data "$ADMINSERV_CREATEMATCHSET"
    echo "    maps-creatematchset.php erfolgreich gepatcht."
fi

# ============================================================
# RemoteCP: Mods-Plugin settings.xml aktualisieren (fuer bestehende Volumes)
# ============================================================
# Die vorkonfigurierte Skin-Liste aus dem Image wird in das Volume
# kopiert, falls die alte Standard-settings.xml noch vorhanden ist
# (erkennbar am Beispiel-Eintrag "blacksunonline.com").
# ============================================================
MODS_SETTINGS_FILE="/var/www/html/remotecp/plugins/Mods/settings.xml"
MODS_SETTINGS_DEFAULT="/opt/tmserver/default-controlpanel/remotecp/plugins/Mods/settings.xml"
if [ -f "$MODS_SETTINGS_FILE" ] && grep -q 'blacksunonline.com' "$MODS_SETTINGS_FILE"; then
    echo "==> Aktualisiere RemoteCP Mods-Plugin (Skin-Liste von techniverse.net)..."
    cp "$MODS_SETTINGS_DEFAULT" "$MODS_SETTINGS_FILE"
    chown www-data:www-data "$MODS_SETTINGS_FILE"
    echo "    Mods/settings.xml erfolgreich aktualisiert."
fi

# ============================================================
# AdminServ: Konfigurationspasswort absichern (fuer bestehende Volumes)
# ============================================================
# AdminServ wird mit einem oeffentlich bekannten Standard-Hash
# ausgeliefert (0b28a5799a32c687dad2c5183718ceac, aus dem
# AdminServ-GitHub-Repo). Dieser wird durch einen zufaelligen
# MD5-Hash ersetzt, damit die /config-Seite abgesichert ist.
# ============================================================
ADMINSERV_CFG_VOL="/var/www/html/config/adminserv.cfg.php"
if [ -f "$ADMINSERV_CFG_VOL" ] && grep -q "0b28a5799a32c687dad2c5183718ceac" "$ADMINSERV_CFG_VOL"; then
    echo "==> SICHERHEIT: AdminServ-Konfigurationspasswort wird ersetzt (Standard-Hash erkannt)..."
    RANDOM_HASH=$(head -c 32 /dev/urandom | md5sum | cut -d' ' -f1)
    sed -i "s|const PASSWORD = '0b28a5799a32c687dad2c5183718ceac';|const PASSWORD = '${RANDOM_HASH}';|" "$ADMINSERV_CFG_VOL"
    echo "    Standard-Hash durch zufaelligen Hash ersetzt."
    echo "    Die /config-Seite ist jetzt abgesichert."
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

# ============================================================
# AdminServ ServerOptions: Exportierte Einstellungen anwenden
# ============================================================
# Falls ein AdminServ-Export in GameData/Config/AdminServ/ServerOptions/
# vorhanden ist, werden die darin enthaltenen Werte (z.B. Servername,
# Beschreibung, Spielerzahl) in die dedicated_cfg.txt uebernommen.
# So bleiben Aenderungen, die ueber AdminServ vorgenommen und exportiert
# wurden, auch nach einem Container-Neustart erhalten.
# ============================================================
ADMINSERV_OPTIONS_DIR="$GAMEDATA_DIR/Config/AdminServ/ServerOptions"
if [ -d "$ADMINSERV_OPTIONS_DIR" ]; then
    LATEST_EXPORT=$(ls -t "$ADMINSERV_OPTIONS_DIR"/*.txt "$ADMINSERV_OPTIONS_DIR"/*.xml 2>/dev/null | head -1)
    if [ -n "$LATEST_EXPORT" ] && [ -f "$LATEST_EXPORT" ]; then
        echo "==> AdminServ ServerOptions-Export gefunden: $(basename "$LATEST_EXPORT")"
        echo "    Uebernehme exportierte Einstellungen in dedicated_cfg.txt..."
        php -r '
            $xmlFile = $argv[1];
            $cfgFile = $argv[2];

            // AdminServ-Export parsen
            $dom = new DOMDocument();
            if (!@$dom->load($xmlFile)) {
                echo "    WARNUNG: AdminServ-Export konnte nicht gelesen werden.\n";
                exit(0);
            }
            $root = $dom->documentElement;
            $exportValues = [];
            foreach ($root->childNodes as $node) {
                if ($node->nodeType === XML_ELEMENT_NODE) {
                    $exportValues[$node->nodeName] = $node->nodeValue;
                }
            }

            // Mapping: AdminServ-XML-Feld => dedicated_cfg.txt-Feld
            $mapping = [
                "Name"                   => "name",
                "Comment"                => "comment",
                "HideServer"             => "hide_server",
                "NextMaxPlayers"         => "max_players",
                "Password"               => "password",
                "PasswordForSpectator"   => "password_spectator",
                "NextMaxSpectators"      => "max_spectators",
                "NextLadderMode"         => "ladder_mode",
                "NextCallVoteTimeOut"    => "callvote_timeout",
                "CallVoteRatio"          => "callvote_ratio",
                "AllowChallengeDownload" => "allow_challenge_download",
                "AutoSaveReplays"        => "autosave_replays",
                "IsP2PUpload"            => "enable_p2p_upload",
                "IsP2PDownload"          => "enable_p2p_download",
            ];

            // Bool-Felder: 1/0 => True/False (dedicated_cfg.txt-Format)
            $boolFields = [
                "allow_challenge_download", "autosave_replays",
                "enable_p2p_upload", "enable_p2p_download",
            ];

            // Ladder-Modus: 0 => inactive, 1 => forced
            $ladderMap = ["0" => "inactive", "1" => "forced"];

            // Zu ersetzende Werte aufbauen
            $replacements = [];
            foreach ($mapping as $xmlField => $cfgField) {
                if (isset($exportValues[$xmlField])) {
                    $value = $exportValues[$xmlField];
                    if (in_array($cfgField, $boolFields)) {
                        $value = ($value == "1" || strtolower($value) === "true") ? "True" : "False";
                    }
                    if ($cfgField === "ladder_mode" && isset($ladderMap[$value])) {
                        $value = $ladderMap[$value];
                    }
                    $replacements[$cfgField] = $value;
                }
            }

            if (empty($replacements)) {
                echo "    Keine anwendbaren Einstellungen im Export gefunden.\n";
                exit(0);
            }

            // dedicated_cfg.txt zeilenweise verarbeiten
            // Nur Tags innerhalb von <server_options> werden ersetzt,
            // damit <name> und <password> in <authorization_levels> unangetastet bleiben.
            $lines = file($cfgFile);
            $inServerOptions = false;
            $updated = 0;

            foreach ($lines as $i => $line) {
                if (strpos($line, "<server_options>") !== false) {
                    $inServerOptions = true;
                }
                if (strpos($line, "</server_options>") !== false) {
                    $inServerOptions = false;
                }
                if ($inServerOptions) {
                    foreach ($replacements as $field => $value) {
                        $pattern = "/(<" . preg_quote($field, "/") . ">)[^<]*(<\/" . preg_quote($field, "/") . ">)/";
                        if (preg_match($pattern, $line)) {
                            $safeValue = htmlspecialchars($value, ENT_XML1 | ENT_QUOTES, "UTF-8");
                            // $ und \ im Replacement escapen, damit preg_replace
                            // sie nicht als Backreferences interpretiert (wichtig
                            // fuer TM-Farbcodes wie $03F, $z, $s etc.)
                            $escapedValue = str_replace(["\\", "$"], ["\\\\", "\\$"], $safeValue);
                            $lines[$i] = preg_replace($pattern, "\${1}" . $escapedValue . "\${2}", $line, 1);
                            echo "    " . $field . " => " . $value . "\n";
                            $updated++;
                            unset($replacements[$field]);
                            break;
                        }
                    }
                }
            }

            if ($updated > 0) {
                file_put_contents($cfgFile, implode("", $lines));
                echo "    " . $updated . " Einstellung(en) aus AdminServ-Export uebernommen.\n";
            }
        ' "$LATEST_EXPORT" "$CONFIG"
    fi
else
    echo "==> Kein AdminServ ServerOptions-Verzeichnis gefunden. Ueberspringe Import."
fi

# ============================================================
# MatchSettings: Neueste Datei automatisch ermitteln
# ============================================================
# Ueber die Umgebungsvariable MATCHSETTINGS_FILE kann gesteuert werden,
# welche MatchSettings-Datei beim Serverstart geladen wird:
#   - "auto"  (Standard): Die neueste .txt-Datei im MatchSettings-Ordner
#     wird automatisch anhand des Aenderungsdatums ermittelt.
#   - "<dateiname.txt>": Eine bestimmte Datei wird direkt verwendet.
# Fallback: custom_game_settings.txt (Standard-MatchSettings aus dem Image).
# ============================================================

MATCHSETTINGS_DIR="$GAMEDATA_DIR/Tracks/MatchSettings"
MATCHSETTINGS_FILE_ENV="${MATCHSETTINGS_FILE:-auto}"

if [ "$MATCHSETTINGS_FILE_ENV" = "auto" ]; then
    echo "==> MatchSettings: Automatische Erkennung (MATCHSETTINGS_FILE=auto)..."
    # Neueste .txt-Datei im MatchSettings-Ordner anhand des Aenderungsdatums ermitteln
    NEWEST_MS=$(ls -t "$MATCHSETTINGS_DIR"/*.txt 2>/dev/null | head -1)
    if [ -n "$NEWEST_MS" ] && [ -f "$NEWEST_MS" ]; then
        MS_FILENAME=$(basename "$NEWEST_MS")
        GAME_SETTINGS_PATH="MatchSettings/${MS_FILENAME}"
        echo "    Neueste MatchSettings gefunden: ${MS_FILENAME}"
        echo "    Aenderungsdatum: $(stat -c '%y' "$NEWEST_MS" 2>/dev/null || ls -la "$NEWEST_MS" | awk '{print $6, $7, $8}')"
    else
        GAME_SETTINGS_PATH="MatchSettings/custom_game_settings.txt"
        echo "    Keine .txt-Dateien in ${MATCHSETTINGS_DIR} gefunden."
        echo "    Fallback: ${GAME_SETTINGS_PATH}"
    fi
else
    # Explizit angegebene Datei verwenden
    if [ -f "$MATCHSETTINGS_DIR/$MATCHSETTINGS_FILE_ENV" ]; then
        GAME_SETTINGS_PATH="MatchSettings/${MATCHSETTINGS_FILE_ENV}"
        echo "==> MatchSettings: Verwende explizit gesetzte Datei: ${MATCHSETTINGS_FILE_ENV}"
    else
        echo "==> WARNUNG: Angegebene MatchSettings-Datei nicht gefunden: ${MATCHSETTINGS_FILE_ENV}"
        echo "    Vorhandene Dateien in ${MATCHSETTINGS_DIR}:"
        ls -la "$MATCHSETTINGS_DIR"/*.txt 2>/dev/null || echo "    (keine .txt-Dateien vorhanden)"
        GAME_SETTINGS_PATH="MatchSettings/custom_game_settings.txt"
        echo "    Fallback: ${GAME_SETTINGS_PATH}"
    fi
fi

echo "    Aktive MatchSettings: ${GAME_SETTINGS_PATH}"

# ============================================================
# MatchSettings: Map-Reihenfolge zufaellig mischen
# ============================================================
# Ueber die Umgebungsvariable SHUFFLE_MAPLIST kann gesteuert werden,
# ob die Reihenfolge der Maps in der aktiven MatchSettings-Datei
# beim Containerstart zufaellig durchgemischt wird:
#   - "false" (Standard): Reihenfolge bleibt unveraendert.
#   - "true":  Alle <challenge>-Eintraege werden zufaellig gemischt
#              und <startindex> wird auf 0 gesetzt.
# Die originale Datei wird dabei ueberschrieben.
# ============================================================

SHUFFLE_MAPLIST="${SHUFFLE_MAPLIST:-false}"

if [ "$SHUFFLE_MAPLIST" = "true" ]; then
    # Vollstaendigen Pfad zur aktiven MatchSettings-Datei bestimmen
    ACTIVE_MS_FILE="$GAMEDATA_DIR/Tracks/${GAME_SETTINGS_PATH}"
    if [ -f "$ACTIVE_MS_FILE" ]; then
        echo "==> Map-Shuffle: Mische Maps in ${GAME_SETTINGS_PATH}..."
        php -r '
            $file = $argv[1];
            $xml = file_get_contents($file);
            if ($xml === false) {
                echo "    FEHLER: Konnte MatchSettings-Datei nicht lesen.\n";
                exit(1);
            }

            // Alle <challenge>...</challenge>-Bloecke extrahieren
            if (!preg_match_all("/<challenge>.*?<\/challenge>/s", $xml, $matches)) {
                echo "    Keine <challenge>-Eintraege gefunden. Shuffle uebersprungen.\n";
                exit(0);
            }

            $challenges = $matches[0];
            $count = count($challenges);
            echo "    $count Maps gefunden. Mische Reihenfolge...\n";

            // Zufaellig mischen
            shuffle($challenges);

            // Alle bestehenden <challenge>-Bloecke aus dem XML entfernen
            $xmlClean = preg_replace("/(\s*<challenge>.*?<\/challenge>)+/s", "", $xml, 1);

            // Gemischte Challenges vor </playlist> wieder einfuegen
            $challengeBlock = "";
            foreach ($challenges as $ch) {
                $challengeBlock .= "\t" . $ch . "\n";
            }
            $xmlNew = str_replace("</playlist>", $challengeBlock . "</playlist>", $xmlClean);

            // <startindex> auf 0 setzen (damit ab der ersten gemischten Map gestartet wird)
            $xmlNew = preg_replace("/<startindex>[^<]*<\/startindex>/", "<startindex>0</startindex>", $xmlNew);

            // Datei zurueckschreiben
            if (file_put_contents($file, $xmlNew) === false) {
                echo "    FEHLER: Konnte MatchSettings-Datei nicht schreiben.\n";
                exit(1);
            }

            // Erste 3 Maps anzeigen
            echo "    Reihenfolge erfolgreich gemischt.\n";
            echo "    Neue Startreihenfolge (erste 3 Maps):\n";
            for ($i = 0; $i < min(3, $count); $i++) {
                if (preg_match("/<file>(.*?)<\/file>/", $challenges[$i], $m)) {
                    echo "      " . ($i + 1) . ". " . $m[1] . "\n";
                }
            }
            if ($count > 3) echo "      ... und " . ($count - 3) . " weitere Maps\n";
        ' "$ACTIVE_MS_FILE"
    else
        echo "==> Map-Shuffle: MatchSettings-Datei nicht gefunden: ${ACTIVE_MS_FILE}"
        echo "    Shuffle uebersprungen."
    fi
else
    echo "==> Map-Shuffle: Deaktiviert (SHUFFLE_MAPLIST=false)."
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

echo "Launching Server in ${SERVER_MODE} mode (MatchSettings: ${GAME_SETTINGS_PATH})"
./TrackmaniaServer /dedicated_cfg=dedicated_cfg.txt /game_settings=${GAME_SETTINGS_PATH} /nodaemon ${LAUNCH_MODE} &
TM_PID=$!
echo "TrackmaniaServer gestartet (PID: ${TM_PID})"

# ============================================================
# Warte auf XMLRPC-Verfuegbarkeit
# ============================================================
# Sowohl XAseco als auch Forced Mods benoetigen eine aktive
# XMLRPC-Verbindung zum TrackmaniaServer.
# ============================================================
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
    echo "    XMLRPC-Port ${XMLRPC_PORT} erreichbar."
else
    echo "    WARNUNG: XMLRPC-Port ${XMLRPC_PORT} nicht erreichbar nach 60s!"
fi

# ============================================================
# Forced Mods (Skins) per XMLRPC setzen
# ============================================================
# Wenn FORCE_MOD_*-Variablen gesetzt sind, werden die
# entsprechenden Mods per SetForcedMods-XMLRPC-Aufruf beim
# Serverstart automatisch aktiviert. Dies funktioniert bei
# jedem Containerstart und ist unabhaengig von FORCE_CONFIG_UPDATE.
# ============================================================

# Pruefen, ob mindestens ein Mod gesetzt ist (Variable fuer spaeter)
HAS_MODS=false
if [ "$XMLRPC_READY" = "true" ]; then
    for ENV_NAME in FORCE_MOD_STADIUM FORCE_MOD_ISLAND FORCE_MOD_BAY FORCE_MOD_COAST FORCE_MOD_SPEED FORCE_MOD_ALPINE FORCE_MOD_RALLY; do
        eval "MOD_VAL=\${$ENV_NAME:-}"
        if [ -n "$MOD_VAL" ]; then
            HAS_MODS=true
            break
        fi
    done
fi

# ============================================================
# XAseco starten (nach TrackmaniaServer, VOR Forced Mods)
# ============================================================
# XAseco muss zuerst starten und sich initialisieren, damit
# es die Forced Mods nicht ueberschreibt oder zuruecksetzt.
# ============================================================
if [ "$XMLRPC_READY" = "true" ]; then
    if [ "${XASECO_ENABLED:-true}" = "true" ] && [ -f "/opt/tmserver/xaseco/aseco.php" ]; then
        echo "==> Starte XAseco..."
        cd /opt/tmserver/xaseco
        php aseco.php TMN </dev/null >>aseco.log 2>&1 &
        XASECO_PID=$!
        echo "$XASECO_PID" > /tmp/xaseco.pid
        echo "    XAseco gestartet (PID: ${XASECO_PID})"
        cd /opt/tmserver

        # XAseco Healthcheck / Watchdog starten
        XASECO_HEALTHCHECK="${XASECO_HEALTHCHECK:-true}"
        if [ "$XASECO_HEALTHCHECK" = "true" ] && [ -f "/opt/tmserver/XAsecoHealthcheck.sh" ]; then
            echo "==> Starte XAseco-Healthcheck (Watchdog)..."
            /opt/tmserver/XAsecoHealthcheck.sh &
            HEALTHCHECK_PID=$!
            echo "    XAseco-Healthcheck gestartet (PID: ${HEALTHCHECK_PID})"
        elif [ "$XASECO_HEALTHCHECK" != "true" ]; then
            echo "==> XAseco-Healthcheck ist deaktiviert (XASECO_HEALTHCHECK=${XASECO_HEALTHCHECK})."
        fi
    elif [ "${XASECO_ENABLED:-true}" != "true" ]; then
        echo "==> XAseco ist deaktiviert (XASECO_ENABLED=${XASECO_ENABLED})." 
    fi
else
    echo "    WARNUNG: XMLRPC nicht erreichbar - XAseco und Forced Mods wurden NICHT gestartet."
fi

# ============================================================
# Forced Mods (Skins) per XMLRPC setzen
# ============================================================
# Wird NACH XAseco-Start ausgefuehrt, damit XAseco die Mods
# nicht bei seiner Initialisierung zuruecksetzt.
# ============================================================
if [ "$XMLRPC_READY" = "true" ] && [ "$HAS_MODS" = "true" ]; then
    # Warten, damit XAseco und der TM-Server sich vollstaendig initialisieren
    echo "==> Forced Mods: Warte 10 Sekunden auf vollstaendige Server-Initialisierung..."
    sleep 10

    echo "==> Forced Mods: Setze Mods per XMLRPC..."

    # JSON-Array der Mods aufbauen
    MODS_JSON="["
    MODS_FIRST=true
    for PAIR in "FORCE_MOD_STADIUM:Stadium" "FORCE_MOD_ISLAND:Island" "FORCE_MOD_BAY:Bay" "FORCE_MOD_COAST:Coast" "FORCE_MOD_SPEED:Speed" "FORCE_MOD_ALPINE:Alpine" "FORCE_MOD_RALLY:Rally"; do
        VAR_NAME="${PAIR%%:*}"
        ENV_NAME="${PAIR##*:}"
        eval "MOD_URL=\${$VAR_NAME:-}"
        if [ -n "$MOD_URL" ]; then
            if [ "$MODS_FIRST" = "true" ]; then
                MODS_FIRST=false
            else
                MODS_JSON="${MODS_JSON},"
            fi
            # URL fuer JSON escapen (Backslash und Anfuehrungszeichen)
            SAFE_URL=$(printf '%s' "$MOD_URL" | sed 's/\\/\\\\/g; s/"/\\"/g')
            MODS_JSON="${MODS_JSON}{\"Env\":\"${ENV_NAME}\",\"Url\":\"${SAFE_URL}\"}"
            echo "    ${ENV_NAME} => ${MOD_URL}"
        fi
    done
    MODS_JSON="${MODS_JSON}]"

    # GBXRemote2-Protokoll: Authenticate + SetForcedMods
    SA_PW_MODS="${SERVER_SA_PASSWORD:-SuperAdmin}"
    php -r '
        $port = (int)$argv[1];
        $password = $argv[2];
        $modsJson = $argv[3];

        $mods = json_decode($modsJson, true);
        if (empty($mods)) { echo "    Keine Mods zu setzen.\n"; exit(0); }

        // GBXRemote2: Verbindung herstellen
        $fp = @fsockopen("127.0.0.1", $port, $errno, $errstr, 5);
        if (!$fp) { echo "    FEHLER: Verbindung zu XMLRPC fehlgeschlagen ($errno: $errstr).\n"; exit(1); }
        stream_set_timeout($fp, 10);

        // Handshake lesen (4 Bytes Laenge + Protokollstring)
        $data = fread($fp, 4);
        if (strlen($data) < 4) { echo "    FEHLER: Handshake fehlgeschlagen.\n"; fclose($fp); exit(1); }
        $info = unpack("Vsize", $data);
        $handshake = fread($fp, $info["size"]);
        if (strpos($handshake, "GBXRemote") === false) {
            echo "    FEHLER: Kein GBXRemote-Protokoll.\n"; fclose($fp); exit(1);
        }
        echo "    Protokoll: $handshake\n";

        $reqhandle = 0x80000001;

        // XML-RPC-Wert kodieren
        function encodeVal($v) {
            if (is_bool($v)) return "<value><boolean>" . ($v ? "1" : "0") . "</boolean></value>";
            if (is_int($v)) return "<value><int>" . $v . "</int></value>";
            if (is_string($v)) return "<value><string>" . htmlspecialchars($v, ENT_XML1) . "</string></value>";
            if (is_array($v)) {
                if (array_keys($v) !== range(0, count($v) - 1)) {
                    $x = "<value><struct>";
                    foreach ($v as $k => $val) $x .= "<member><name>" . $k . "</name>" . encodeVal($val) . "</member>";
                    return $x . "</struct></value>";
                } else {
                    $x = "<value><array><data>";
                    foreach ($v as $val) $x .= encodeVal($val);
                    return $x . "</data></array></value>";
                }
            }
            return "<value><string>" . htmlspecialchars((string)$v, ENT_XML1) . "</string></value>";
        }

        // Ein einzelnes Paket vom Server lesen (Header + Body)
        function readPacket($fp) {
            $header = "";
            while (strlen($header) < 8) {
                $chunk = @fread($fp, 8 - strlen($header));
                if ($chunk === false || strlen($chunk) === 0) return false;
                $header .= $chunk;
            }
            $info = unpack("Vsize/Vhandle", $header);
            $size = $info["size"];
            $handle = $info["handle"];
            if ($size > 4194304 || $size == 0) return false;

            $body = "";
            $remaining = $size;
            while ($remaining > 0) {
                $chunk = @fread($fp, min($remaining, 8192));
                if ($chunk === false || strlen($chunk) === 0) break;
                $body .= $chunk;
                $remaining -= strlen($chunk);
            }
            return ["handle" => $handle, "body" => $body];
        }

        // XMLRPC-Request senden und Antwort lesen
        // Callbacks (handle < 0x80000000) werden uebersprungen
        function gbxQuery($fp, &$reqhandle, $method, $params) {
            $xml = "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
                 . "<methodCall><methodName>" . $method . "</methodName><params>";
            foreach ($params as $p) $xml .= "<param>" . encodeVal($p) . "</param>";
            $xml .= "</params></methodCall>";

            $myHandle = $reqhandle++;
            $packet = pack("VV", strlen($xml), $myHandle) . $xml;
            $written = @fwrite($fp, $packet);
            if ($written === false || $written === 0) {
                echo "    FEHLER: Konnte Request nicht senden ($method).\n";
                return false;
            }

            // Auf Antwort warten, Callbacks ueberspringen
            for ($attempt = 0; $attempt < 30; $attempt++) {
                $pkt = readPacket($fp);
                if ($pkt === false) {
                    echo "    FEHLER: Keine Antwort fuer $method.\n";
                    return false;
                }
                // Callback? (Handle < 0x80000000) -> ueberspringen
                if ($pkt["handle"] < 0x80000000) {
                    continue;
                }
                // Response gefunden
                return $pkt["body"];
            }
            echo "    FEHLER: Zu viele Callbacks, keine Antwort fuer $method.\n";
            return false;
        }

        // 1. Authenticate
        echo "    Authentifiziere als SuperAdmin...\n";
        $resp = gbxQuery($fp, $reqhandle, "Authenticate", ["SuperAdmin", $password]);
        if ($resp === false || strpos($resp, "<boolean>1</boolean>") === false) {
            echo "    FEHLER: Authentifizierung fehlgeschlagen.\n";
            if ($resp) echo "    Antwort: " . substr(trim($resp), 0, 500) . "\n";
            fclose($fp); exit(1);
        }
        echo "    Authentifizierung erfolgreich.\n";

        // 2. EnableCallbacks deaktivieren (weniger Rauschen)
        gbxQuery($fp, $reqhandle, "EnableCallbacks", [false]);

        // 3. SetForcedMods(override=true, mods=[{Env, Url}, ...])
        // Debug: Zeige das XML das wir senden
        $setXml = "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
                . "<methodCall><methodName>SetForcedMods</methodName><params>"
                . "<param>" . encodeVal(true) . "</param>"
                . "<param>" . encodeVal($mods) . "</param>"
                . "</params></methodCall>";
        echo "    Debug SetForcedMods-XML:\n    " . $setXml . "\n";

        echo "    Sende SetForcedMods (" . count($mods) . " Mod(s))...\n";
        $resp = gbxQuery($fp, $reqhandle, "SetForcedMods", [true, $mods]);
        echo "    SetForcedMods-Antwort: " . trim($resp) . "\n";
        if ($resp !== false && strpos($resp, "<boolean>1</boolean>") !== false) {
            echo "    SetForcedMods: OK\n";
        } else {
            echo "    FEHLER: SetForcedMods fehlgeschlagen.\n";
        }

        // 4. GetForcedMods zur Verifikation (vollstaendige Antwort)
        echo "    Verifiziere mit GetForcedMods...\n";
        $resp = gbxQuery($fp, $reqhandle, "GetForcedMods", []);
        echo "    GetForcedMods-Antwort:\n    " . trim($resp) . "\n";

        fclose($fp);
    ' "$XMLRPC_PORT" "$SA_PW_MODS" "$MODS_JSON"
elif [ "$XMLRPC_READY" = "true" ]; then
    echo "==> Forced Mods: Keine FORCE_MOD_*-Variablen gesetzt. Ueberspringe."
fi

# Auf TrackmaniaServer warten (Hauptprozess)
wait $TM_PID
