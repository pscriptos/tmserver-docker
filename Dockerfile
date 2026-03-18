FROM debian:bookworm-slim

RUN mkdir /opt/tmserver

WORKDIR /opt/tmserver

# Alle benoetigten Pakete in einem Layer installieren und Cache aufraeumen
RUN apt-get update && apt-get install -y --no-install-recommends \
    unzip \
    apache2 \
    php \
    php-zip \
    php-xml \
    && rm -rf /var/lib/apt/lists/*

COPY assets/bin/TrackmaniaServer_2011-02-21.zip /opt/tmserver
RUN unzip /opt/tmserver/TrackmaniaServer_2011-02-21.zip -d /opt/tmserver \
    && rm -f /opt/tmserver/TrackmaniaServer_2011-02-21.zip

# Custom-Konfiguration ueber die Standard-Config aus dem ZIP kopieren
COPY assets/config/dedicated_cfg.txt /opt/tmserver/GameData/Config/dedicated_cfg.txt
COPY assets/config/custom_game_settings.txt /opt/tmserver/GameData/Tracks/MatchSettings/

# Gesamtes GameData als Default-Template sichern (wird beim ersten Start ins Volume kopiert)
RUN cp -r /opt/tmserver/GameData /opt/tmserver/default-gamedata

COPY assets/bin/RunTrackmaniaServer.sh /opt/tmserver/
RUN sed -i 's/\r$//' /opt/tmserver/RunTrackmaniaServer.sh \
    && chmod +x /opt/tmserver/RunTrackmaniaServer.sh

COPY assets/bin/AdminServ_v2.1.1.zip /var/www/html
RUN unzip /var/www/html/AdminServ_v2.1.1.zip -d /var/www/html \
    && rm -f /var/www/html/AdminServ_v2.1.1.zip \
    && chmod -R 777 /var/www/html/ \
    && rm -f /var/www/html/index.html

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

# Volume fuer persistente GameData (Config, Tracks, Skins, Scores, etc.)
VOLUME /opt/tmserver/GameData

EXPOSE 5000/tcp
EXPOSE 2350/tcp
EXPOSE 2350/udp
EXPOSE 3450/tcp
EXPOSE 80/tcp

CMD ["/opt/tmserver/RunTrackmaniaServer.sh"]
