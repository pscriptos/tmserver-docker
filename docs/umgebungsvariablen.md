# Umgebungsvariablen

Alle Umgebungsvariablen werden über die `.env`-Datei konfiguriert, die von `docker-compose.yml` automatisch eingelesen wird. Alternativ können sie beim `docker run` über `--env-file .env` oder einzeln mit `-e` gesetzt werden.

Die Variablen werden beim **ersten Start** (leeres GameData-Volume) in die `dedicated_cfg.txt` eingetragen. Bei weiteren Starts bleiben manuelle Änderungen erhalten. Siehe [Konfiguration](konfiguration.md) für Details.

> **Sicherheitshinweis:** Sensible Werte (Passwörter, Keys) sind **nicht** im Docker-Image hinterlegt. Sie werden ausschließlich zur Laufzeit über die `.env`-Datei übergeben. Die `.env`-Datei ist über `.gitignore` und `.dockerignore` geschützt und wird weder ins Git noch in den Docker-Build-Context aufgenommen.

## Einrichtung

```bash
# Vorlage kopieren
cp .env.example .env

# Werte anpassen
nano .env
```

> **⚠ Sicherheitshinweis:** Die `.env.example` enthält **vorgenerierte Beispiel-Passwörter**. Diese dienen nur als Platzhalter und sind öffentlich einsehbar! **Ändere unbedingt alle Passwörter**, bevor du den Server produktiv einsetzt. Betroffen sind: `SERVER_SA_PASSWORD`, `SERVER_ADM_PASSWORD`, `SERVER_USER_PASSWORD`, `MARIADB_ROOT_PASSWORD`, `REMOTECP_DB_PASSWORD` und `XASECO_DB_PASSWORD`.

## Authentifizierung

| Variable | Beschreibung | Standard |
|----------|-------------|----------|
| `SERVER_SA_PASSWORD` | SuperAdmin-Passwort | `SuperAdmin` |
| `SERVER_ADM_PASSWORD` | Admin-Passwort | `Admin` |
| `SERVER_USER_PASSWORD` | User-Passwort | `User` |

## Masterserver-Account

| Variable | Beschreibung | Standard |
|----------|-------------|----------|
| `SERVER_LOGIN` | Masterserver-Login (nur Internet-Modus) | *(leer)* |
| `SERVER_LOGIN_PASSWORD` | Masterserver-Passwort | *(leer)* |
| `SERVER_VALIDATION_KEY` | Masterserver-Validierungsschlüssel | *(leer)* |

> **Wichtig:** Im Internet-Modus müssen `SERVER_LOGIN` und `SERVER_VALIDATION_KEY` gesetzt sein, andernfalls startet der Server nicht.

## Server-Optionen

| Variable | Beschreibung | Standard |
|----------|-------------|----------|
| `SERVER_NAME` | Servername (im Spiel sichtbar) | `Trackmania Server` |
| `SERVER_DESC` | Serverbeschreibung | `Powered by tmserver-docker` |
| `SERVER_HIDE` | Server verstecken (`0` = sichtbar, `1` = versteckt, `2` = vor Nations versteckt) | `0` |
| `SERVER_MAX_PLAYERS` | Maximale Spieleranzahl | `32` |
| `SERVER_PASSWORD` | Passwort zum Beitreten (leer = offen) | *(leer)* |
| `SERVER_MAX_SPECTATORS` | Maximale Zuschaueranzahl | `32` |
| `SERVER_SPEC_PASSWORD` | Zuschauer-Passwort (leer = offen) | *(leer)* |
| `SERVER_LADDER_MODE` | Ladder-Modus (`inactive` oder `forced`) | `forced` |
| `SERVER_LADDER_LIMIT_MAX` | Oberes Ladder-Serverlimit (Punktegrenze) | `60000` |

## Netzwerk

| Variable | Beschreibung | Standard |
|----------|-------------|----------|
| `SERVER_PORT` | Gameserver-Port | `2350` |
| `SERVER_P2P_PORT` | P2P-Port | `3450` |
| `SERVER_XMLRPC_PORT` | XML-RPC-Port (intern für AdminServ) | `5000` |
| `SERVER_UPLOAD_RATE` | Upload-Rate in Kbps | `512` |
| `SERVER_DOWNLOAD_RATE` | Download-Rate in Kbps | `8192` |

## Server-Modus & Steuerung

| Variable | Beschreibung | Standard |
|----------|-------------|----------|
| `SERVER_MODE` | Server-Modus (`internet` oder `lan`) | `internet` |
| `FORCE_CONFIG_UPDATE` | Erzwingt erneutes Anwenden aller Umgebungsvariablen auf die Config | `false` |

## Spieleinstellungen (MatchSettings)

| Variable | Beschreibung | Standard |
|----------|-------------|----------|
| `ALLWARMUPDURATION` | Warmup-Dauer für alle Runden (`0` = deaktiviert, `1` = eine Runde Warmup) | `0` |

## RemoteCP

RemoteCP verwendet die SuperAdmin-Zugangsdaten (`SERVER_SA_PASSWORD`) des TM-Servers für den Web-Login. Es werden keine separaten Login-Variablen benötigt.

| Variable | Beschreibung | Standard |
|----------|-------------|----------|
| `REMOTECP_DB_HOST` | Hostname des Datenbankservers | `mariadb` |
| `REMOTECP_DB_NAME` | Name der RemoteCP-Datenbank | `remotecp` |
| `REMOTECP_DB_USER` | Datenbank-Benutzername | `remotecp` |
| `REMOTECP_DB_PASSWORD` | Datenbank-Passwort | *(muss gesetzt werden)* |

> **Hinweis:** Diese Werte werden nur beim ersten Start (leeres Volume) angewendet. Weitere Details unter [RemoteCP](remotecp.md).

## MariaDB

| Variable | Beschreibung | Standard |
|----------|-------------|----------|
| `MARIADB_ROOT_PASSWORD` | Root-Passwort für den MariaDB-Server | *(muss gesetzt werden)* |

> **Wichtig:** `MARIADB_ROOT_PASSWORD` muss gesetzt sein, damit der MariaDB-Container startet. Die Datenbank und der Benutzer für RemoteCP werden automatisch aus `REMOTECP_DB_NAME`, `REMOTECP_DB_USER` und `REMOTECP_DB_PASSWORD` erstellt.

> **Hinweis:** Der MariaDB-Container kann mehrere Datenbanken beherbergen. Zusätzliche Datenbanken und Benutzer können über den Root-Zugang erstellt werden.

## XAseco

XAseco ist ein Server-Controller für Rekorde, Karma, Jukebox und mehr. Siehe [XAseco](xaseco.md) für Details.

| Variable | Beschreibung | Standard |
|----------|-------------|----------|
| `XASECO_ENABLED` | XAseco aktivieren/deaktivieren | `true` |
| `XASECO_MASTERADMIN_LOGIN` | Dein Spieler-Login (MasterAdmin) | *(muss gesetzt werden)* |
| `XASECO_DB_HOST` | Hostname des Datenbankservers | `mariadb` |
| `XASECO_DB_NAME` | Name der XAseco-Datenbank | `xaseco` |
| `XASECO_DB_USER` | Datenbank-Benutzername | `xaseco` |
| `XASECO_DB_PASSWORD` | Datenbank-Passwort | *(muss gesetzt werden)* |
| `XASECO_DEDIMANIA_NATION` | Dedimania-Nation (IOC-Code) | `DEU` |

> **Hinweis:** Die Server-Zugangsdaten (`SERVER_SA_PASSWORD`, `SERVER_XMLRPC_PORT`) und Dedimania-Daten (`SERVER_LOGIN`, `SERVER_LOGIN_PASSWORD`) werden automatisch aus der bestehenden Konfiguration übernommen.

## Debugging

| Variable | Beschreibung | Standard |
|----------|-------------|----------|
| `PHP_DISPLAY_ERRORS` | Aktiviert den PHP-Debug-Modus: Fehlermeldungen im Browser + vollständige Warnungen im Log (nur zur Fehlersuche!) | `false` |

> **Hinweis:** Der Debug-Modus erfordert **keinen** Rebuild des Images. Es genügt, die Variable in der `.env`-Datei zu ändern und den Container neu zu starten (`docker compose restart`). Im Produktivbetrieb sollte `PHP_DISPLAY_ERRORS` immer auf `false` stehen.
>
> Bei `false` werden nur schwerwiegende Fehler geloggt (keine Warnungen/Notices). Bei `true` werden zusätzlich alle Warnungen und Hinweise angezeigt und geloggt – nützlich zur Fehlersuche bei Problemen mit RemoteCP oder AdminServ.

> **Hinweis:** Bei `FORCE_CONFIG_UPDATE=true` wird die `dedicated_cfg.txt` aus dem Template neu erzeugt und alle Platzhalter mit den aktuellen Umgebungsvariablen ersetzt. Manuelle Änderungen gehen dabei verloren! Nach dem Update sollte `FORCE_CONFIG_UPDATE` wieder auf `false` gesetzt werden.

## Beispiel

### Docker Compose (empfohlen)

Passe die Werte in der `.env`-Datei an und starte mit:

```bash
docker compose up -d
```

> **Tipp:** Das fertige Docker Image wird automatisch aus der [Container-Registry](https://git.techniverse.net/scriptos/-/packages/container/trackmania-server/) geladen. Wenn du das Image selbst bauen möchtest, verwende stattdessen `docker compose up -d --build`.

### docker run

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

Einzelne Werte können zusätzlich überschrieben werden:

```bash
docker run -d \
  --env-file .env \
  -e SERVER_NAME="Mein Server" \
  -e SERVER_MAX_PLAYERS=64 \
  -p 2350:2350/tcp \
  -p 2350:2350/udp \
  -p 3450:3450/tcp \
  -p 80:80/tcp \
  -v ./data/gamedata:/opt/tmserver/GameData \
  -v ./data/controlpanel:/var/www/html \
  -v ./data/xaseco:/opt/tmserver/xaseco \
  --name tmserver git.techniverse.net/scriptos/trackmania-server:latest
```
