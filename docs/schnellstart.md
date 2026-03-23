# Schnellstart

## Voraussetzungen

- Docker und Docker Compose müssen installiert sein

## 1. Umgebungsvariablen einrichten

Kopiere die Vorlage und passe die Werte an:

```bash
cp .env.example .env
```

Bearbeite die `.env`-Datei und setze mindestens die gewünschten Passwörter. Für den Internet-Modus müssen zusätzlich `SERVER_LOGIN` und `SERVER_VALIDATION_KEY` gesetzt werden.

> **⚠ Sicherheitshinweis:** Die `.env.example` enthält **vorgenerierte Beispiel-Passwörter**. Diese dienen nur als Platzhalter und sind öffentlich einsehbar! **Ändere unbedingt alle Passwörter**, bevor du den Server produktiv einsetzt.

> **Wichtig:** Die `.env`-Datei enthält sensible Daten (Passwörter, Keys) und wird über die `.gitignore` vom Einchecken ausgeschlossen.

## 2. Server starten

### Fertiges Docker Image verwenden (empfohlen)

Es steht ein fertiges Docker Image in der Container-Registry bereit – kein eigener Build nötig:

```
git.techniverse.net/scriptos/trackmania-server:latest
```

> **Tipp:** Alle verfügbaren Tags findest du in der [Container-Registry](https://git.techniverse.net/scriptos/-/packages/container/trackmania-server/).

#### Mit Docker Compose

```bash
docker compose up -d
```

Die Konfiguration erfolgt über die `.env`-Datei, die automatisch eingelesen wird. Das Image wird automatisch aus der Registry geladen.

### Docker Image selbst bauen

Alternativ kannst du das Image auch selbst bauen:

```bash
docker build -t tmserver:latest -t tmserver:1.3.0 .
```

Damit wird das Image mit zwei Tags erstellt: `tmserver:latest` und `tmserver:1.3.0`.

Anschließend den Server starten:

```bash
docker compose up -d --build
```

### Internet-Modus (docker run)

Für den Internet-Modus wird ein Server-Account benötigt. Dieser kann auf der [Trackmania Players-Seite](https://players.trackmaniaforever.com) erstellt werden.

```bash
docker run -d \
  --env-file .env \
  -p 2350:2350/tcp \
  -p 2350:2350/udp \
  -p 3450:3450/tcp \
  -p 80:80/tcp \
  -v ./data/gamedata:/opt/tmserver/GameData \
  -v ./data/controlpanel:/var/www/html \
  -v ./data/xaseco:/opt/tmserver/xaseco \
  --name tmserver git.techniverse.net/scriptos/trackmania-server:latest
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
  -v ./data/gamedata:/opt/tmserver/GameData \
  -v ./data/controlpanel:/var/www/html \
  -v ./data/xaseco:/opt/tmserver/xaseco \
  --name tmserver git.techniverse.net/scriptos/trackmania-server:latest
```

## 3. Verwaltungsoberflächen öffnen

| Tool | URL | Beschreibung |
|------|-----|-------------|
| AdminServ | `http://<host-ip>/` | Server-Verwaltungsoberfläche |
| RemoteCP | `http://<host-ip>/remotecp/` | Alternative Verwaltungsoberfläche |

Weitere Details unter [AdminServ](adminserv.md) und [RemoteCP](remotecp.md).

## Persistente Konfiguration

Alle Server- und AdminServ-Daten werden über Bind-Mounts persistent auf dem Host gespeichert:

| Host-Pfad | Container-Pfad | Beschreibung |
|-----------|----------------|-------------|
| `./data/gamedata` | `/opt/tmserver/GameData` | TM-Server-Daten (Config, Tracks, Skins, etc.) |
| `./data/controlpanel` | `/var/www/html` | AdminServ- und RemoteCP-Daten |
| `./data/xaseco` | `/opt/tmserver/xaseco` | XAseco-Konfiguration und Logs |
| `./data/mariadb` | `/var/lib/mysql` | MariaDB-Datenbankdateien |

Beim ersten Start werden die Verzeichnisse automatisch aus dem Image erzeugt und die Umgebungsvariablen aus der `.env`-Datei angewendet. Bei weiteren Starts bleibt alles erhalten.

Weitere Details unter [Konfiguration](konfiguration.md).
