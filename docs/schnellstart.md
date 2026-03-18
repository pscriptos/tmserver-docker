# Schnellstart

## Voraussetzungen

- Docker muss installiert sein

## Docker Image bauen

Bevor der Server gestartet werden kann, muss das Docker Image gebaut werden. Führe dazu im Projektverzeichnis folgenden Befehl aus:

```bash
docker build -t tmserver:latest -t tmserver:1.0.0 .
```

Damit wird das Image mit zwei Tags erstellt: `tmserver:latest` und `tmserver:1.0.0`. Das Tag `latest` verweist immer auf die aktuelle Version, während `1.0.0` eine feste Versionskennung darstellt.

> **Hinweis:** In den folgenden `docker run`-Beispielen muss der Image-Name entsprechend durch `tmserver:latest` oder `tmserver:1.0.0` ersetzt werden.

## Internet-Dedicated-Modus (Standard)

Für den Internet-Modus wird ein Server-Account benötigt. Dieser kann auf der [Trackmania Players-Seite](https://players.trackmaniaforever.com) erstellt werden.

```bash
docker run -d \
  -p 2350:2350/tcp \
  -p 2350:2350/udp \
  -p 3450:3450/tcp \
  -p 80:80/tcp \
  -e SERVER_LOGIN=dein_login \
  -e SERVER_VALIDATION_KEY=dein_key \
  --name tm-server lduriez/tmserver
```

## LAN-Modus

Für den LAN-Modus werden keine Masterserver-Zugangsdaten benötigt:

```bash
docker run -d \
  -p 2350:2350/tcp \
  -p 2350:2350/udp \
  -p 3450:3450/tcp \
  -p 80:80/tcp \
  -e SERVER_MODE=lan \
  --name tm-server lduriez/tmserver
```

## Docker Compose

Alternativ kann der Server mit Docker Compose gestartet werden:

```bash
docker compose up -d
```

Passe dazu die Werte in der `docker-compose.yml` an. Weitere Details unter [Umgebungsvariablen](umgebungsvariablen.md).
