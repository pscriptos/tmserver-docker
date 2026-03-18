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

## Debugging

| Variable | Beschreibung | Standard |
|----------|-------------|----------|
| `PHP_DISPLAY_ERRORS` | Zeigt PHP-Fehlermeldungen im Browser an (nur zur Fehlersuche!) | `false` |

> **Hinweis:** Der Debug-Modus erfordert **keinen** Rebuild des Images. Es genügt, die Variable in der `.env`-Datei zu ändern und den Container neu zu starten (`docker compose restart`). Im Produktivbetrieb sollte `PHP_DISPLAY_ERRORS` immer auf `false` stehen.

> **Hinweis:** Bei `FORCE_CONFIG_UPDATE=true` wird die `dedicated_cfg.txt` aus dem Template neu erzeugt und alle Platzhalter mit den aktuellen Umgebungsvariablen ersetzt. Manuelle Änderungen gehen dabei verloren! Nach dem Update sollte `FORCE_CONFIG_UPDATE` wieder auf `false` gesetzt werden.

## Beispiel

### Docker Compose (empfohlen)

Passe die Werte in der `.env`-Datei an und starte mit:

```bash
docker compose up -d --build
```

### docker run

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
  -v ./data/GameData:/opt/tmserver/GameData \
  --name tmserver tmserver:latest
```
