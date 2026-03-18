# Schnellstart

## Voraussetzungen

- Docker und Docker Compose müssen installiert sein

## 1. Umgebungsvariablen einrichten

Kopiere die Vorlage und passe die Werte an:

```bash
cp .env.example .env
```

Bearbeite die `.env`-Datei und setze mindestens die gewünschten Passwörter. Für den Internet-Modus müssen zusätzlich `SERVER_LOGIN` und `SERVER_VALIDATION_KEY` gesetzt werden.

> **Wichtig:** Die `.env`-Datei enthält sensible Daten (Passwörter, Keys) und wird über die `.gitignore` vom Einchecken ausgeschlossen.

## 2. Docker Image bauen

```bash
docker build -t tmserver:latest -t tmserver:1.0.0 .
```

Damit wird das Image mit zwei Tags erstellt: `tmserver:latest` und `tmserver:1.0.0`.

## 3. Server starten

### Mit Docker Compose (empfohlen)

```bash
docker compose up -d --build
```

Die Konfiguration erfolgt über die `.env`-Datei, die automatisch eingelesen wird.

### Internet-Modus (docker run)

Für den Internet-Modus wird ein Server-Account benötigt. Dieser kann auf der [Trackmania Players-Seite](https://players.trackmaniaforever.com) erstellt werden.

```bash
docker run -d \
  --env-file .env \
  -p 2350:2350/tcp \
  -p 2350:2350/udp \
  -p 3450:3450/tcp \
  -p 80:80/tcp \
  -v ./data/GameData:/opt/tmserver/GameData \
  --name tmserver tmserver:latest
```

### LAN-Modus (docker run)

Setze in der `.env`-Datei `SERVER_MODE=lan` oder übergib es direkt:

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

## 4. AdminServ öffnen

Die Verwaltungsoberfläche ist unter `http://<host-ip>` erreichbar. Weitere Details unter [AdminServ](adminserv.md).

## Persistente Konfiguration

Die gesamten Server-Daten (`GameData/`) werden über einen Bind-Mount (`./data/GameData`) persistent auf dem Host gespeichert. Beim ersten Start wird das gesamte GameData-Verzeichnis automatisch aus dem Image erzeugt und die Umgebungsvariablen aus der `.env`-Datei angewendet. Bei weiteren Starts bleibt alles erhalten.

Weitere Details unter [Konfiguration](konfiguration.md).
