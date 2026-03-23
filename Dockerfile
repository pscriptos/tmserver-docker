FROM debian:bullseye-slim

RUN mkdir /opt/tmserver

WORKDIR /opt/tmserver

# Alle benoetigten Pakete in einem Layer installieren und Cache aufraeumen
RUN apt-get update && apt-get install -y --no-install-recommends \
    unzip \
    apache2 \
    php \
    php-zip \
    php-xml \
    php-mbstring \
    php-mysql \
    php-curl \
    default-mysql-client \
    logrotate \
    && rm -rf /var/lib/apt/lists/*

# Apache mod_rewrite aktivieren und AllowOverride fuer .htaccess (RemoteCP-Sicherheit)
RUN a2enmod rewrite \
    && sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

COPY assets/bin/TrackmaniaServer_2011-02-21.zip /opt/tmserver
RUN unzip /opt/tmserver/TrackmaniaServer_2011-02-21.zip -d /opt/tmserver \
    && rm -f /opt/tmserver/TrackmaniaServer_2011-02-21.zip

# Custom-Konfiguration ueber die Standard-Config aus dem ZIP kopieren
COPY assets/config/dedicated_cfg.txt /opt/tmserver/GameData/Config/dedicated_cfg.txt
COPY assets/config/custom_game_settings.txt /opt/tmserver/GameData/Tracks/MatchSettings/

# Config-Verzeichnis rekursiv beschreibbar machen (Server benoetigt Schreibzugriff)
RUN chmod -R 777 /opt/tmserver/GameData/Config/

# Tracks-Verzeichnis fuer AdminServ beschreibbar machen (Maps-Upload/Download)
RUN chown -R www-data:www-data /opt/tmserver/GameData/Tracks/ \
    && chmod -R 755 /opt/tmserver/GameData/Tracks/

# AdminServ-Verzeichnisse im Config-Ordner anlegen
RUN mkdir -p /opt/tmserver/GameData/Config/AdminServ/ServerOptions \
    && chown -R www-data:www-data /opt/tmserver/GameData/Config/AdminServ

# Gesamtes GameData als Default-Template sichern (wird beim ersten Start ins Volume kopiert)
RUN cp -a /opt/tmserver/GameData /opt/tmserver/default-gamedata

COPY assets/bin/RunTrackmaniaServer.sh /opt/tmserver/
RUN sed -i 's/\r$//' /opt/tmserver/RunTrackmaniaServer.sh \
    && chmod +x /opt/tmserver/RunTrackmaniaServer.sh

COPY assets/bin/XAsecoHealthcheck.sh /opt/tmserver/
RUN sed -i 's/\r$//' /opt/tmserver/XAsecoHealthcheck.sh \
    && chmod +x /opt/tmserver/XAsecoHealthcheck.sh

COPY assets/bin/AdminServ_v2.1.1.zip /var/www/html
RUN unzip /var/www/html/AdminServ_v2.1.1.zip -d /var/www/html \
    && rm -f /var/www/html/AdminServ_v2.1.1.zip \
    && rm -f /var/www/html/index.html \
    && mkdir -p /var/www/html/logs \
    && chmod -R 777 /var/www/html/logs \
    && chmod 666 /var/www/html/config/adminlevel.cfg.php \
    && chmod 666 /var/www/html/config/servers.cfg.php \
    && chmod 666 /var/www/html/config/adminserv.cfg.php \
    && chown -R www-data:www-data /var/www/html/

# RemoteCP installieren (als Subpath /remotecp/)
COPY assets/bin/remoteCP_v4.0.3.5.zip /var/www/html
RUN unzip /var/www/html/remoteCP_v4.0.3.5.zip -d /var/www/html \
    && mv /var/www/html/remoteCP_4.0.3.5-1 /var/www/html/remotecp \
    && rm -f /var/www/html/remoteCP_v4.0.3.5.zip \
    && mkdir -p /var/www/html/remotecp/cache \
    && chmod -R 777 /var/www/html/remotecp/cache \
    && chmod -R 666 /var/www/html/remotecp/xml/*.xml \
    && chmod -R 777 /var/www/html/remotecp/xml \
    && chmod -R 777 /var/www/html/remotecp/xml/settings \
    && chown -R www-data:www-data /var/www/html/remotecp/

# Fix PHP-Warnungen in RemoteCP CustomPoints-Plugin (undefined constants)
# RemoteCP nutzt bare constants (pt_custom, pt_points, ...), die in PHP 7.2+
# Warnungen ausloesen. Das gepatchte Plugin nutzt stattdessen defined()-Pruefungen.
COPY assets/config/remotecp/plugins/CustomPoints/index.php /var/www/html/remotecp/plugins/CustomPoints/index.php
RUN chown www-data:www-data /var/www/html/remotecp/plugins/CustomPoints/index.php

# Fix PHP-Warnungen in RemoteCP Mods-Plugin (foreach auf leere Umgebungen)
# Leere Umgebungen (Island, Bay, …) fuehrten zu "Invalid argument supplied
# for foreach()", weil $this->mods['Env'] nicht initialisiert war.
# Zusaetzlich bare-constant-Warnungen (pt_*) mit defined()-Pruefungen entschaerft.
COPY assets/config/remotecp/plugins/Mods/index.php /var/www/html/remotecp/plugins/Mods/index.php
RUN chown www-data:www-data /var/www/html/remotecp/plugins/Mods/index.php

# RemoteCP Mods-Plugin: Vorkonfigurierte Skin-Liste (techniverse.net)
COPY assets/config/remotecp/plugins/Mods/settings.xml /var/www/html/remotecp/plugins/Mods/settings.xml
RUN chown www-data:www-data /var/www/html/remotecp/plugins/Mods/settings.xml

# Fix AdminServ MatchSettings-Bugs fuer TmForever:
# 1) get_matchset_mapimport.php: Falscher Pfad-Praefix (MatchSettings/ statt
#    des tatsaechlichen Map-Ordners) beim Erstellen von MatchSettings.
# 2) maps-creatematchset.php: GetModeScriptInfo-Aufruf (existiert nur in
#    ManiaPlanet/TM2) wird fuer TmForever uebersprungen.
COPY assets/config/adminserv/get_matchset_mapimport.php /var/www/html/resources/ajax/get_matchset_mapimport.php
COPY assets/config/adminserv/maps-creatematchset.php /var/www/html/resources/process/maps-creatematchset.php
RUN chown www-data:www-data /var/www/html/resources/ajax/get_matchset_mapimport.php \
    && chown www-data:www-data /var/www/html/resources/process/maps-creatematchset.php

# AdminServ- und RemoteCP-Dateien als Default-Template sichern (wird beim ersten Start ins Volume kopiert)
RUN cp -a /var/www/html /opt/tmserver/default-controlpanel

# XAseco installieren
COPY assets/bin/xaseco_v1.16.zip /opt/tmserver/
RUN unzip /opt/tmserver/xaseco_v1.16.zip -d /opt/tmserver/ \
    && rm -f /opt/tmserver/xaseco_v1.16.zip \
    # newinstall-Dateien in den Hauptordner verschieben
    && cp /opt/tmserver/xaseco/newinstall/access.xml /opt/tmserver/xaseco/ \
    && cp /opt/tmserver/xaseco/newinstall/adminops.xml /opt/tmserver/xaseco/ \
    && cp /opt/tmserver/xaseco/newinstall/Aseco.sh /opt/tmserver/xaseco/ \
    && cp /opt/tmserver/xaseco/newinstall/AsecoF.sh /opt/tmserver/xaseco/ \
    && cp /opt/tmserver/xaseco/newinstall/autotime.xml /opt/tmserver/xaseco/ \
    && cp /opt/tmserver/xaseco/newinstall/bannedips.xml /opt/tmserver/xaseco/ \
    && cp /opt/tmserver/xaseco/newinstall/config.xml /opt/tmserver/xaseco/ \
    && cp /opt/tmserver/xaseco/newinstall/dedimania.xml /opt/tmserver/xaseco/ \
    && cp /opt/tmserver/xaseco/newinstall/html.tpl /opt/tmserver/xaseco/ \
    && cp /opt/tmserver/xaseco/newinstall/localdatabase.xml /opt/tmserver/xaseco/ \
    && cp /opt/tmserver/xaseco/newinstall/matchsave.xml /opt/tmserver/xaseco/ \
    && cp /opt/tmserver/xaseco/newinstall/musicserver.xml /opt/tmserver/xaseco/ \
    && cp /opt/tmserver/xaseco/newinstall/plugins.xml /opt/tmserver/xaseco/ \
    && cp /opt/tmserver/xaseco/newinstall/rasp.xml /opt/tmserver/xaseco/ \
    && cp /opt/tmserver/xaseco/newinstall/text.tpl /opt/tmserver/xaseco/ \
    # Die drei PHP-Dateien nach includes/
    && cp /opt/tmserver/xaseco/newinstall/jfreu.config.php /opt/tmserver/xaseco/includes/ \
    && cp /opt/tmserver/xaseco/newinstall/rasp.settings.php /opt/tmserver/xaseco/includes/ \
    && cp /opt/tmserver/xaseco/newinstall/votes.config.php /opt/tmserver/xaseco/includes/ \
    # Start-Scripte ausfuehrbar machen
    && chmod +x /opt/tmserver/xaseco/Aseco.sh \
    && chmod +x /opt/tmserver/xaseco/AsecoF.sh \
    # newinstall-Ordner aufraeumen
    && rm -rf /opt/tmserver/xaseco/newinstall

# Nicht mehr verfuegbares freezone-Plugin entfernen
RUN sed -i '/<plugin>plugin\.freezone\.php<\/plugin>/d' /opt/tmserver/xaseco/plugins.xml

# TeamSpeak3-Plugin: Eigenes Gateway einbinden (Original-Gateway nicht mehr verfuegbar)
# Die teamspeak3.xml wird direkt in den XAseco-Ordner kopiert, damit das Plugin
# beim Start automatisch den konfigurierten TS3-Server anzeigt.
COPY assets/config/xaseco/teamspeak3.xml /opt/tmserver/xaseco/teamspeak3.xml

# XAseco als Default-Template sichern (wird beim ersten Start ins Volume kopiert)
RUN cp -a /opt/tmserver/xaseco /opt/tmserver/default-xaseco

# PHP-Debug-Konfiguration: wird zur Laufzeit vom Startup-Script gesetzt
# (kein Rebuild noetig – nur Container neustarten)

# Log-Rotation: logrotate-Konfiguration ins Image kopieren
# Wird zur Laufzeit stuendlich per Background-Loop ausgefuehrt (kein cron noetig).
COPY assets/config/logrotate.conf /etc/logrotate.d/tmserver
RUN chmod 644 /etc/logrotate.d/tmserver

# --- Umgebungsvariablen ---
# Sensible Werte (Passwoerter, Keys) werden NICHT im Image hinterlegt,
# sondern muessen zur Laufzeit uebergeben werden (z.B. via .env-Datei).

# Server-Optionen (nicht-sensible Standardwerte)
ENV SERVER_NAME="Trackmania Server"
ENV SERVER_DESC="Powered by tmserver-docker"
ENV SERVER_HIDE=0
ENV SERVER_MAX_PLAYERS=32
ENV SERVER_MAX_SPECTATORS=32
ENV SERVER_LADDER_MODE=forced

# Netzwerk
ENV SERVER_PORT=2350
ENV SERVER_P2P_PORT=3450
ENV SERVER_XMLRPC_PORT=5000
ENV SERVER_UPLOAD_RATE=512
ENV SERVER_DOWNLOAD_RATE=8192

# Server-Modus und Config-Steuerung
ENV SERVER_MODE=internet
ENV FORCE_CONFIG_UPDATE=false

# Spieleinstellungen (MatchSettings)
ENV ALLWARMUPDURATION=0
ENV SHUFFLE_MAPLIST=false

# Forced Mods (Skins) - URL zu ZIP-Dateien, die beim Start forciert werden
ENV FORCE_MOD_STADIUM=""
ENV FORCE_MOD_ISLAND=""
ENV FORCE_MOD_BAY=""
ENV FORCE_MOD_COAST=""
ENV FORCE_MOD_SPEED=""
ENV FORCE_MOD_ALPINE=""
ENV FORCE_MOD_RALLY=""

# RemoteCP
ENV REMOTECP_DB_HOST=mariadb
ENV REMOTECP_DB_NAME=remotecp
ENV REMOTECP_DB_USER=remotecp

# XAseco
ENV XASECO_ENABLED=true
ENV XASECO_MASTERADMIN_LOGIN=""
ENV XASECO_DB_HOST=mariadb
ENV XASECO_DB_NAME=xaseco
ENV XASECO_DB_USER=xaseco
ENV XASECO_DEDIMANIA_NATION=DEU
ENV XASECO_HEALTHCHECK=true
ENV XASECO_HEALTHCHECK_INTERVAL=60

# Debugging
ENV PHP_DISPLAY_ERRORS=false

# Volumes fuer persistente Daten
VOLUME /opt/tmserver/GameData
VOLUME /var/www/html
VOLUME /opt/tmserver/xaseco

EXPOSE 5000/tcp
EXPOSE 2350/tcp
EXPOSE 2350/udp
EXPOSE 3450/tcp
EXPOSE 80/tcp

# Graceful Shutdown: SIGTERM wird vom Signal-Handler im Startscript abgefangen
# und alle Dienste (XAseco, TM-Server, Apache) sauber heruntergefahren.
STOPSIGNAL SIGTERM

CMD ["/opt/tmserver/RunTrackmaniaServer.sh"]
