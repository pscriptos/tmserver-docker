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
| `./data/xaseco` | `/opt/tmserver/xaseco` | XAseco-Konfiguration und Logs |
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
  --name tmserver git.techniverse.net/scriptos/trackmania-server:latest
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
| `AdminServ/ServerOptions/` | Von AdminServ exportierte Server-Einstellungen |

## Graceful Shutdown

Beim Stoppen des Containers (`docker compose stop`, `docker compose down` oder `docker stop`) werden alle Dienste **sauber und in der richtigen Reihenfolge** heruntergefahren:

1. **XAseco-Healthcheck** – wird zuerst beendet, damit XAseco nicht während des Shutdowns neu gestartet wird
2. **XAseco** – beendet sich ordentlich und schließt alle Datenbank-Connections (verhindert DB-Korruption)
3. **TrackmaniaServer** – der Spielserver wird sauber gestoppt
4. **Apache** – AdminServ und RemoteCP werden beendet
5. **Log-Rotation** – Hintergrundprozess wird gestoppt

Jeder Dienst hat maximal 10 Sekunden Zeit, sich sauber zu beenden. Falls ein Prozess nicht reagiert, wird er zwangsweise beendet (SIGKILL). Die `stop_grace_period` in der `docker-compose.yml` ist auf 30 Sekunden gesetzt, um genügend Zeit für den gesamten Shutdown-Prozess zu geben.

Der Shutdown-Fortschritt wird in der Konsole protokolliert und kann mit `docker logs tmserver` nachvollzogen werden.

> **Hinweis:** Der Graceful Shutdown ist nach einem Image-Update automatisch aktiv – auch bei bestehenden Installationen. Es sind keine manuellen Schritte nötig.

## Log-Rotation

Alle Log-Dateien im Container werden automatisch per `logrotate` rotiert, damit sie nicht unbegrenzt wachsen. Die Rotation läuft **größenbasiert** als Hintergrundprozess (stündliche Prüfung, kein Cron nötig).

### Einstellungen

| Parameter | Wert |
|-----------|------|
| Maximale Dateigröße | 10 MB |
| Rotierte Dateien behalten | 5 |
| Komprimierung | Ja (gzip, verzögert) |
| Leere Logs überspringen | Ja |

### Rotierte Log-Dateien

| Log | Pfad im Container | Persistenz |
|-----|--------------------|------------|
| Apache Access | `/var/log/apache2/access.log` | Nur im Container |
| Apache Error | `/var/log/apache2/error.log` | Nur im Container |
| PHP Errors | `/var/log/php_errors.log` | Nur im Container |
| XAseco | `/opt/tmserver/xaseco/aseco.log` | Volume (`./data/xaseco/`) |
| AdminServ | `/var/www/html/logs/*.log` | Volume (`./data/controlpanel/logs/`) |

Rotierte Dateien werden als `*.1` (vorherige), `*.2.gz`, `*.3.gz` usw. aufbewahrt.

### Konfigurationsdatei

Die logrotate-Konfiguration liegt im Image unter `/etc/logrotate.d/tmserver` (Quelle: `assets/config/logrotate.conf`). Sie wird beim Bau des Images fest eingebettet und erfordert keine manuelle Anpassung.

> **Hinweis:** Die Log-Rotation ist nach einem Image-Update automatisch aktiv – auch bei bestehenden Installationen. Es sind keine manuellen Schritte nötig.

## Startup-Zusammenfassung

Nach Abschluss des gesamten Startprozesses wird automatisch eine übersichtliche Zusammenfassung aller wichtigen Server-Informationen als formatierte Box in der Konsole ausgegeben. Die Box-Breite passt sich dynamisch an den längsten Inhalt an.

**Angezeigte Informationen:**

| Bereich | Details |
|---------|---------|
| **Server** | Servername, Modus (Internet/LAN), Ladder, Spieler-/Zuschauerlimit |
| **Netzwerk** | Server-Port, P2P-Port, XMLRPC-Port |
| **Maps** | Aktive MatchSettings-Datei, Anzahl geladener Maps, Shuffle-Status |
| **Dienste** | XAseco-Status (mit PID), Healthcheck, Forced Mods |
| **Web-Interfaces** | AdminServ- und RemoteCP-URLs |
| **System** | Log-Rotation, PHP-Debug-Modus, TM-Server-PID |

**Beispielausgabe:**

```
╔════════════════════════════════════════════════════════════════╗
║     TrackMania Nations Forever - Server gestartet              ║
╠════════════════════════════════════════════════════════════════╣
║  Servername:     Mein Trackmania Server                        ║
║  Modus:          Internet (Ladder: forced)                     ║
║  Spieler:        max. 32 Spieler / 32 Zuschauer                ║
║  Server-Port:    2350 (TCP/UDP) | P2P: 3450 (TCP)              ║
║  XMLRPC-Port:    5000                                          ║
╠════════════════════════════════════════════════════════════════╣
║  MatchSettings:  custom_game_settings.txt                      ║
║  Maps:           24 Maps geladen                               ║
║  Map-Shuffle:    Deaktiviert                                   ║
╠════════════════════════════════════════════════════════════════╣
║  XAseco:         Aktiv (PID 1234)                              ║
║  Healthcheck:    Aktiv (PID 5678)                              ║
║  Forced Mods:    Keine                                         ║
╠════════════════════════════════════════════════════════════════╣
║  AdminServ:      http://<host-ip>/                             ║
║  RemoteCP:       http://<host-ip>/remotecp/                    ║
╠════════════════════════════════════════════════════════════════╣
║  Log-Rotation:   Aktiv (stuendlich, max. 10 MB)                ║
║  PHP-Debug:      Deaktiviert                                   ║
║  TM-Server:      PID 42                                        ║
╚════════════════════════════════════════════════════════════════╝
```

Die Zusammenfassung kann jederzeit mit `docker logs tmserver` erneut eingesehen werden.

> **Hinweis:** Die Startup-Zusammenfassung ist nach einem Image-Update automatisch aktiv – auch bei bestehenden Installationen. Es sind keine manuellen Schritte nötig.

## AdminServ ServerOptions-Import

Wenn über AdminServ Änderungen an den Server-Optionen vorgenommen und als Export gespeichert werden (z.B. Servername, Beschreibung, Spielerzahl), werden diese beim nächsten Container-Start **automatisch** in die `dedicated_cfg.txt` übernommen.

**Ablauf:**

1. In AdminServ unter „Server Options" die gewünschten Einstellungen ändern und „Export" klicken
2. Die exportierte Datei wird in `GameData/Config/AdminServ/ServerOptions/` gespeichert
3. Beim nächsten Start des Containers wird die **neueste** Export-Datei erkannt
4. Die darin enthaltenen Werte werden in die `dedicated_cfg.txt` geschrieben

**Unterstützte Felder:**

| AdminServ-Feld | dedicated_cfg.txt-Feld |
|----------------|----------------------|
| `Name` | `<name>` |
| `Comment` | `<comment>` |
| `HideServer` | `<hide_server>` |
| `NextMaxPlayers` | `<max_players>` |
| `Password` | `<password>` |
| `PasswordForSpectator` | `<password_spectator>` |
| `NextMaxSpectators` | `<max_spectators>` |
| `NextLadderMode` | `<ladder_mode>` |
| `NextCallVoteTimeOut` | `<callvote_timeout>` |
| `CallVoteRatio` | `<callvote_ratio>` |
| `AllowChallengeDownload` | `<allow_challenge_download>` |
| `AutoSaveReplays` | `<autosave_replays>` |
| `IsP2PUpload` | `<enable_p2p_upload>` |
| `IsP2PDownload` | `<enable_p2p_download>` |

> **Hinweis:** Die AdminServ-Exports haben **Vorrang** vor den Werten aus den Umgebungsvariablen. Beim ersten Start werden zunächst die Umgebungsvariablen angewendet, danach die AdminServ-Exports (falls vorhanden). Bei weiteren Starts werden nur die AdminServ-Exports angewendet.

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

## MatchSettings (Spieleinstellungen)

Die MatchSettings-Dateien liegen im Verzeichnis `data/gamedata/Tracks/MatchSettings/` und definieren Spielmodus, Regeln und die aktive Track-Liste des Servers. Sie werden als `.txt`-Dateien im XML-Format gespeichert.

### Automatische Erkennung (Standard)

Standardmäßig wird beim Serverstart automatisch die **neueste** `.txt`-Datei im MatchSettings-Ordner anhand des Änderungsdatums geladen. So werden z.B. über AdminServ erstellte oder bearbeitete MatchSettings beim nächsten Neustart automatisch aktiv.

```bash
# In der .env-Datei (Standardwert):
MATCHSETTINGS_FILE=auto
```

**Ablauf bei jedem Containerstart:**

1. Der Ordner `data/gamedata/Tracks/MatchSettings/` wird nach `.txt`-Dateien durchsucht
2. Die Datei mit dem neuesten Änderungsdatum wird ermittelt
3. Diese Datei wird als `/game_settings`-Parameter an den TM-Server übergeben
4. Dateiname und Änderungsdatum werden in der Konsole ausgegeben

### Bestimmte Datei verwenden

Alternativ kann eine bestimmte MatchSettings-Datei direkt angegeben werden:

```bash
# In der .env-Datei:
MATCHSETTINGS_FILE=turnier_settings.txt
```

Der Dateiname bezieht sich immer auf den Ordner `data/gamedata/Tracks/MatchSettings/`.

### Fallback

Falls die angegebene oder automatisch ermittelte Datei nicht existiert, wird auf die mitgelieferte Standard-Datei `custom_game_settings.txt` zurückgefallen.

### Neue MatchSettings über AdminServ erstellen

1. In AdminServ mit SuperAdmin einloggen
2. Unter „Maps" → „MatchSettings" → „Create" eine neue Datei anlegen
3. Tracks aus den gewünschten Ordnern importieren (z.B. `Challenges/Downloaded/`)
4. Spielmodus und Regeln konfigurieren
5. Speichern – die Datei wird in `MatchSettings/` abgelegt
6. Container neustarten (`docker compose restart`) – die neue Datei wird automatisch als neueste erkannt und geladen

> **Hinweis:** Die aktive MatchSettings-Datei wird beim Serverstart in der Konsole ausgegeben. Mit `docker logs tmserver` kann überprüft werden, welche Datei geladen wurde.
