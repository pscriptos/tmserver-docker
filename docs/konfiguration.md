# Konfiguration (dedicated_cfg.txt)

Die Server-Konfiguration wird in der Datei `dedicated_cfg.txt` im Verzeichnis `GameData/Config/` gespeichert. Diese Datei enthält alle wichtigen Parameter für den Serverbetrieb.

Die Template-Konfiguration befindet sich im Repository unter `assets/config/dedicated_cfg.txt`. Sie enthält `%%PLATZHALTER%%` anstelle von echten Werten – keine Passwörter oder Zugangsdaten im Repo! Die Platzhalter werden beim ersten Container-Start durch die [Umgebungsvariablen](umgebungsvariablen.md) ersetzt.

## Persistente Speicherung

Das gesamte **GameData-Verzeichnis** wird über ein Bind-Mount (`./data/gamedata`) persistent auf dem Host gespeichert. Das bedeutet:

- Alle Daten (Konfiguration, Tracks, Skins, Scores, Cache, etc.) bleiben erhalten
- Manuelle Änderungen gehen nicht verloren, auch wenn der Container neu erstellt wird
- Dateien können direkt auf dem Host bearbeitet werden

### Volume-Pfade

| Host-Pfad | Container-Pfad | Beschreibung |
|-----------|----------------|-------------|
| `./data/gamedata` | `/opt/tmserver/GameData` | Gesamtes GameData-Verzeichnis |
| `./data/controlpanel` | `/var/www/html` | AdminServ- und RemoteCP-Daten |
| `./data/mariadb` | `/var/lib/mysql` | MariaDB-Datenbankdateien |

### Enthaltene Unterordner

| Ordner | Beschreibung |
|--------|-------------|
| `Config/` | Server-Konfiguration (`dedicated_cfg.txt`, Blacklist, Guestlist) |
| `Tracks/` | Strecken und MatchSettings |
| `Skins/` | Spieler- und Fahrzeug-Skins |
| `Scores/` | Gespeicherte Punktestände |
| `Cache/` | Server-Cache |
| `Profiles/` | Spielerprofile |
| `Replays/` | Gespeicherte Replays |

## Reihenfolge beim Docker-Build

1. ZIP-Archiv wird entpackt → Standard-`dedicated_cfg.txt` aus dem ZIP landet in `GameData/Config/`
2. Template aus `assets/config/dedicated_cfg.txt` (mit `%%PLATZHALTERN%%`) wird darüber kopiert
3. Gesamtes `GameData/`-Verzeichnis wird als Default-Template gesichert

## First-Run-Verhalten

Beim **ersten Start** des Containers (leeres Volume) passiert Folgendes:

1. Das gesamte Default-GameData-Template wird aus dem Image ins Volume kopiert
2. Alle `%%PLATZHALTER%%` in der `dedicated_cfg.txt` werden durch die [Umgebungsvariablen](umgebungsvariablen.md) ersetzt
3. Der Server startet mit der so erzeugten Konfiguration

Bei **weiteren Starts** wird die vorhandene Konfiguration **nicht überschrieben**. Umgebungsvariablen haben dann keine Wirkung mehr auf die `dedicated_cfg.txt`.

## Konfiguration manuell bearbeiten

Nach dem ersten Start kann die Konfiguration direkt auf dem Host bearbeitet werden:

```bash
# Konfiguration direkt auf dem Host bearbeiten
nano ./data/gamedata/Config/dedicated_cfg.txt

# Alternativ: im Container anzeigen
docker exec tmserver cat /opt/tmserver/GameData/Config/dedicated_cfg.txt

# Server neustarten, damit die Änderungen wirksam werden
docker restart tmserver
```

> **Hinweis:** Da `GameData/` als Bind-Mount eingebunden ist, sind Dateien direkt unter `./data/gamedata/` auf dem Host verfügbar – ohne `docker cp` oder `docker exec`.

## Konfiguration zurücksetzen (FORCE_CONFIG_UPDATE)

Falls die Umgebungsvariablen erneut auf die Konfiguration angewendet werden sollen (z.B. nach einer Passwortänderung), kann die Variable `FORCE_CONFIG_UPDATE` verwendet werden.

In der `.env`-Datei:

```bash
FORCE_CONFIG_UPDATE=true
```

Oder per `docker run`:

```bash
docker run -d \
  --env-file .env \
  -e FORCE_CONFIG_UPDATE=true \
  -p 2350:2350/tcp \
  -p 2350:2350/udp \
  -p 3450:3450/tcp \
  -p 80:80/tcp \
  -v ./data/gamedata:/opt/tmserver/GameData \
  -v ./data/controlpanel:/var/www/html \
  -v ./data/xaseco:/opt/tmserver/xaseco \
  --name tmserver tmserver:latest
```

> **Achtung:** Bei `FORCE_CONFIG_UPDATE=true` wird die `dedicated_cfg.txt` komplett aus dem Template neu erzeugt und alle Platzhalter mit den aktuellen Umgebungsvariablen ersetzt. **Manuelle Änderungen an der Config gehen dabei verloren!** Andere Dateien im GameData-Volume (Tracks, Skins, Scores, etc.) bleiben erhalten. Nach dem Update sollte `FORCE_CONFIG_UPDATE` wieder auf `false` gesetzt werden.

## Wichtige Dateien im Config-Ordner

Der Ordner `GameData/Config/` enthält:

| Datei | Beschreibung |
|-------|-------------|
| `dedicated_cfg.txt` | Haupt-Konfigurationsdatei des Servers |
| `blacklist.txt` | Liste gesperrter Spieler |
| `guestlist.txt` | Liste erlaubter Spieler |
| `Default.SystemConfig.Gbx` | System-Konfiguration |

## Wichtige Parameter in der dedicated_cfg.txt

Alle diese Parameter können über [Umgebungsvariablen](umgebungsvariablen.md) gesetzt werden:

| Parameter | Umgebungsvariable | Standard |
|-----------|------------------|----------|
| `<name>` (SuperAdmin-PW) | `SERVER_SA_PASSWORD` | `SuperAdmin` |
| `<name>` (Admin-PW) | `SERVER_ADM_PASSWORD` | `Admin` |
| `<name>` (User-PW) | `SERVER_USER_PASSWORD` | `User` |
| `<login>` | `SERVER_LOGIN` | *(leer)* |
| `<validation_key>` | `SERVER_VALIDATION_KEY` | *(leer)* |
| `<name>` (Servername) | `SERVER_NAME` | `Trackmania Server` |
| `<comment>` | `SERVER_DESC` | `Powered by tmserver-docker` |
| `<hide_server>` | `SERVER_HIDE` | `0` |
| `<max_players>` | `SERVER_MAX_PLAYERS` | `32` |
| `<password>` | `SERVER_PASSWORD` | *(leer)* |
| `<max_spectators>` | `SERVER_MAX_SPECTATORS` | `32` |
| `<ladder_mode>` | `SERVER_LADDER_MODE` | `forced` |
| `<server_port>` | `SERVER_PORT` | `2350` |
| `<server_p2p_port>` | `SERVER_P2P_PORT` | `3450` |
| `<xmlrpc_port>` | `SERVER_XMLRPC_PORT` | `5000` |
| `<connection_uploadrate>` | `SERVER_UPLOAD_RATE` | `512` |
| `<connection_downloadrate>` | `SERVER_DOWNLOAD_RATE` | `8192` |
