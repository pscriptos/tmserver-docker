# Server-Modi

Der Trackmania-Server kann in zwei Modi betrieben werden.

## Internet-Dedicated (Standard)

Im Internet-Modus ist der Server über das Trackmania-Masterserver-Netzwerk erreichbar und in der öffentlichen Serverliste sichtbar.

### Voraussetzungen

- Ein Server-Account auf der [Trackmania Players-Seite](https://players.trackmaniaforever.com)
- Die Umgebungsvariablen `SERVER_LOGIN` und `SERVER_VALIDATION_KEY` müssen gesetzt sein

### Konfiguration

In der `.env`-Datei:

```bash
SERVER_MODE=internet
SERVER_LOGIN=dein_login
SERVER_LOGIN_PASSWORD=dein_passwort
SERVER_VALIDATION_KEY=dein_key
```

Wenn `SERVER_LOGIN` oder `SERVER_VALIDATION_KEY` nicht gesetzt sind, bricht der Server mit einer Fehlermeldung ab.

### Server-Account erstellen

1. [players.trackmaniaforever.com](https://players.trackmaniaforever.com) aufrufen
2. Einloggen oder einen neuen Account erstellen
3. Unter „Dedicated Server" einen neuen Server-Account anlegen
4. Login und Validation Key notieren und als Umgebungsvariablen setzen

## LAN-Dedicated

Im LAN-Modus ist der Server nur im lokalen Netzwerk erreichbar. Es werden keine Masterserver-Zugangsdaten benötigt.

### Konfiguration

In der `.env`-Datei:

```bash
SERVER_MODE=lan
```

Oder per Docker-Run:

```bash
docker run -d \
  --env-file .env \
  -e SERVER_MODE=lan \
  -p 2350:2350/tcp \
  -p 2350:2350/udp \
  -p 3450:3450/tcp \
  -p 80:80/tcp \
  -v ./data/GameData:/opt/tmserver/GameData \
  --name tmserver tmserver:latest
```
