# AdminServ – Server-Verwaltungsoberfläche

Die Server-Verwaltungsoberfläche basiert auf [AdminServ](https://github.com/Chris92de/AdminServ) und ist über Port 80 erreichbar.

## Einrichtung

AdminServ wird beim ersten Container-Start **vollständig automatisch konfiguriert**:

- Serververbindung (Adresse `127.0.0.1`, XML-RPC-Port)
- Server-Eintrag (Name, DisplayServ-Passwort)
- Konfigurationspasswort (siehe [Konfigurationsseite (`/config`)](#konfigurationsseite-config))

Es ist kein manuelles Setup nötig.

## Verbindung zum Server

1. `http://<host-server-des-containers>` im Browser aufrufen
2. Den Server aus der Liste auswählen
3. Admin-Stufe wählen (SuperAdmin, Admin oder User) und das zugehörige Passwort eingeben

## Standard-Passwörter

| Stufe | Standard-Passwort |
|-------|-------------------|
| SuperAdmin | `SuperAdmin` |
| Admin | `Admin` |
| User | `User` |

Diese Passwörter werden über die `.env`-Datei gesetzt (`SERVER_SA_PASSWORD`, `SERVER_ADM_PASSWORD`, `SERVER_USER_PASSWORD`) und beim ersten Start in die `dedicated_cfg.txt` geschrieben. AdminServ liest die Passwörter über die XML-RPC-Verbindung direkt vom TM-Server.

Die Admin-Stufen können unter `http://<host-server-des-containers>/config` geändert werden.

> **Hinweis:** Die Standard-Passwörter in der `.env.example` sind öffentlich einsehbar. Ändere sie unbedingt, bevor du den Server produktiv einsetzt. Siehe [Umgebungsvariablen](umgebungsvariablen.md).

## Persistente Speicherung

Alle AdminServ-Daten (Passwort, Server-Einträge, Konfiguration, Logs) werden über einen Bind-Mount (`./data/controlpanel`) persistent auf dem Host gespeichert. Beim ersten Start werden die Dateien automatisch aus dem Image ins Volume kopiert.

| Host-Pfad | Container-Pfad | Beschreibung |
|-----------|----------------|-------------|
| `./data/controlpanel` | `/var/www/html` | AdminServ- und RemoteCP-Installation |

> **Hinweis:** Im selben Volume befindet sich auch [RemoteCP](remotecp.md) unter `./data/controlpanel/remotecp/`.

## Fehlerbehebung

### Login funktioniert nicht nach dem Anlegen eines Servers

Falls der Login nicht funktioniert oder ein Authentifizierungsfehler angezeigt wird, können die PHP-Logs Aufschluss geben:

1. In der `.env`-Datei `PHP_DISPLAY_ERRORS=true` setzen
2. Container neu starten: `docker compose up -d`
3. AdminServ im Browser öffnen und den Fehler reproduzieren
4. Die PHP-Fehlermeldung wird direkt auf der Seite angezeigt

Alternativ können die PHP-Logs eingesehen werden:

```bash
docker exec tmserver cat /var/log/php_errors.log
```

> **Hinweis:** Alle Logs (Apache, PHP, AdminServ) werden automatisch per logrotate rotiert (max. 10 MB pro Datei, 5 rotierte Dateien). Siehe [Konfiguration – Log-Rotation](konfiguration.md#log-rotation).

### AdminServ komplett zurücksetzen

Falls AdminServ in einen inkonsistenten Zustand geraten ist:

```bash
# AdminServ-Daten auf dem Host löschen
rm -rf ./data/controlpanel/*

# Container neu starten – AdminServ wird frisch initialisiert
docker compose up -d
```

## Konfigurationsseite (`/config`)

AdminServ bringt unter `http://<host-ip>/config` eine eigene Konfigurationsseite mit, über die Server-Einträge hinzugefügt, geändert oder gelöscht werden können. Diese Seite ist durch ein separates Passwort geschützt (`OnlineConfig::PASSWORD` in `adminserv.cfg.php`, MD5-gehasht).

Da dieser Container als **Standalone-Setup** läuft und ausschließlich den einen lokalen TrackMania-Server bedient, wird die `/config`-Seite **nicht benötigt** – der Server-Eintrag wird beim ersten Start automatisch angelegt (Adresse, XML-RPC-Port, Passwörter).

Zur Absicherung wird das Konfigurationspasswort beim ersten Container-Start automatisch durch einen **zufällig generierten MD5-Hash** ersetzt. Damit ist die `/config`-Seite vor unbefugtem Zugriff geschützt, ohne dass ein Benutzer ein Passwort vergeben oder sich merken muss.

> **Hinweis:** Falls du dennoch Zugriff auf die `/config`-Seite benötigst (z.B. für Debugging), kannst du den MD5-Hash in `data/controlpanel/config/adminserv.cfg.php` manuell auf ein bekanntes Passwort setzen. Beispiel: `const PASSWORD = '5f4dcc3b5aa765d61d8327deb882cf99';` entspricht dem Passwort `password`.

## Gepatchte AdminServ-Bugs (TmForever)

AdminServ (v2.1.1) enthält zwei Bugs, die speziell im Zusammenspiel mit TmForever auftreten. Diese werden beim Container-Start automatisch gepatcht – auch bei bestehenden Volumes.

### Falscher Pfad in MatchSettings-Dateien

Beim Erstellen einer neuen MatchSettings-Datei über AdminServ wurden die Track-Pfade falsch geschrieben. Statt des tatsächlichen Ordners (z.B. `Challenges/Downloaded/`) wurde immer der Speicherort der MatchSettings (`MatchSettings/`) als Pfad-Präfix verwendet:

```xml
<!-- Fehlerhaft (Original) -->
<file>MatchSettings/speed vs. fullspeed.Challenge.Gbx</file>

<!-- Korrekt (nach Patch) -->
<file>Challenges/Downloaded/speed vs. fullspeed.Challenge.Gbx</file>
```

**Ursache:** Die AJAX-Funktion `get_matchset_mapimport.php` hat den URL-Parameter `d` (= MatchSettings-Speicherordner) als relativen Pfad für die Map-Dateinamen verwendet, anstatt den tatsächlichen Ordner aus der Dropdown-Auswahl zu berechnen.

**Betroffene Datei:** `resources/ajax/get_matchset_mapimport.php`

### GetModeScriptInfo-Fehler (-506)

Beim Speichern einer MatchSettings-Datei erschien die Fehlermeldung:

```
[-506] Method 'GetModeScriptInfo' not defined
```

**Ursache:** `GetModeScriptInfo` ist eine XML-RPC-Methode, die nur in ManiaPlanet/TM2 existiert. AdminServ hat sie ohne Versionsprüfung aufgerufen. An anderen Stellen im Code wurde korrekt mit `SERVER_VERSION_NAME != 'TmForever'` unterschieden – nur hier fehlte die Prüfung.

**Betroffene Datei:** `resources/process/maps-creatematchset.php`
