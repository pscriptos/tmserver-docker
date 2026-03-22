# RemoteCP – Alternative Server-Verwaltungsoberfläche

RemoteCP ist eine weitere Web-Verwaltungsoberfläche für Trackmania-Server, die parallel zu AdminServ installiert ist. Es handelt sich um ein älteres Tool mit eigenem Login-System und eigener Benutzerverwaltung.

## Zugriff

RemoteCP ist als Subpath unter der gleichen Adresse wie AdminServ erreichbar:

- **AdminServ:** `http://<host-ip>/`
- **RemoteCP:** `http://<host-ip>/remotecp/`

## Standard-Zugangsdaten

RemoteCP verwendet die SuperAdmin-Zugangsdaten des Trackmania-Servers:

| Benutzer | Passwort | Beschreibung |
|----------|----------|-------------|
| `SuperAdmin` | Wert aus `SERVER_SA_PASSWORD` | Administrator (volle Rechte) |
| `Guest` | `Guest` | Gast-Zugang (nur Lesen) |

Der Admin-Login für RemoteCP ist identisch mit dem SuperAdmin-Passwort des TM-Servers (`SERVER_SA_PASSWORD`). Es werden keine separaten Zugangsdaten benötigt.

## Umgebungsvariablen

| Variable | Beschreibung | Standard |
|----------|-------------|----------|
| `REMOTECP_DB_HOST` | Hostname des Datenbankservers | `mariadb` |
| `REMOTECP_DB_NAME` | Name der RemoteCP-Datenbank | `remotecp` |
| `REMOTECP_DB_USER` | Datenbank-Benutzername | `remotecp` |
| `REMOTECP_DB_PASSWORD` | Datenbank-Passwort | *(muss gesetzt werden)* |

## Datenbank (MariaDB)

RemoteCP benötigt eine MariaDB-Datenbank für erweiterte Funktionen (Spielerstatistiken, Records, Chat-Nachrichten, etc.). Ein MariaDB-Container wird automatisch als Teil des Docker-Setups bereitgestellt.

### Automatische Einrichtung

Wenn die Datenbank-Variablen in der `.env`-Datei gesetzt sind (`REMOTECP_DB_HOST`, `REMOTECP_DB_PASSWORD`), wird beim ersten Start:

1. Die **MariaDB** erstellt automatisch die Datenbank und den Benutzer (über `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD`)
2. Das **Startup-Script** wartet, bis MariaDB erreichbar ist
3. Die **Datenbank-Tabellen** werden automatisch aus den SQL-Schema-Dateien importiert
4. Die **Installer-Markierung** (`cache/installed`) wird gesetzt, damit der Web-Installer übersprungen wird

Es ist kein manuelles Setup über den Web-Installer nötig.

### Manuelle Einrichtung

Falls die automatische Einrichtung nicht gewünscht ist oder fehlschlägt (z.B. MariaDB nicht erreichbar), kann RemoteCP auch manuell eingerichtet werden:

1. Die Datenbank-Variablen (`REMOTECP_DB_HOST`, `REMOTECP_DB_PASSWORD`) **müssen trotzdem in der `.env`-Datei gesetzt sein**, damit die MariaDB die Datenbank und den Benutzer beim ersten Start erstellt
2. RemoteCP-Installer im Browser aufrufen: `http://<host-ip>/remotecp/index.php?page=install`
3. „Install with remoteCP-Database" wählen
4. Die Datenbank-Zugangsdaten eingeben:
   - **Database DSN:** `mysql:dbname=remotecp;host=mariadb` (bzw. die Werte aus der `.env`)
   - **Database Username:** Wert aus `REMOTECP_DB_USER`
   - **Database Password:** Wert aus `REMOTECP_DB_PASSWORD`
5. Server-Daten eingeben (XMLRPC-Port, SuperAdmin-Passwort)
6. Installation abschließen

### Persistente Daten

Die MariaDB-Daten werden über ein eigenes Bind-Mount persistent gespeichert:

| Host-Pfad | Container-Pfad | Beschreibung |
|-----------|----------------|-------------|
| `./data/mariadb` | `/var/lib/mysql` | MariaDB-Datenbankdateien |

> **Hinweis:** Der MariaDB-Container kann auch für weitere Tools genutzt werden. Zusätzliche Datenbanken und Benutzer können über den Root-Zugang (`MARIADB_ROOT_PASSWORD`) erstellt werden.

## Automatische Konfiguration

Beim ersten Start wird RemoteCP automatisch konfiguriert:

- Die **Serververbindung** wird mit dem XML-RPC-Port und dem SuperAdmin-Passwort (`SERVER_SA_PASSWORD`) aus der `.env`-Datei eingerichtet
- Der **Admin-Zugang** verwendet den Benutzernamen `SuperAdmin` mit dem Passwort aus `SERVER_SA_PASSWORD`
- Das Passwort wird als MD5-Hash in der Konfiguration gespeichert
- Die **Datenbankverbindung** wird automatisch in `servers.xml` eingetragen (wenn DB-Variablen gesetzt sind)

## Persistente Speicherung

RemoteCP wird im gleichen Volume wie AdminServ gespeichert:

| Host-Pfad | Container-Pfad | Beschreibung |
|-----------|----------------|-------------|
| `./data/controlpanel/remotecp` | `/var/www/html/remotecp` | RemoteCP-Installation |

Die Konfigurationsdateien befinden sich unter `./data/controlpanel/remotecp/xml/`:

| Datei | Beschreibung |
|-------|-------------|
| `servers.xml` | Server-Verbindungsdaten (Host, Port, Passwort, Datenbank) |
| `admins.xml` | Benutzer und Zugangsdaten |
| `groups.xml` | Berechtigungsgruppen |

## Mods / Skins

RemoteCP enthält ein **Mods-Plugin**, mit dem Texturpakete (Skins) pro Spielumgebung auf dem Server forciert werden können. Spieler laden den jeweiligen Mod automatisch beim Betreten des Servers herunter.

### Wie funktionieren Mods?

In TrackMania Forever sind Mods ZIP-Archive mit alternativen Texturen für eine Spielumgebung (Stadium, Island, Bay, etc.). Der Ablauf:

1. Der Mod liegt als `.zip`-Datei auf einem **Webserver**, der für die Spieler erreichbar ist
2. Der Serveradmin forciert den Mod über den XML-RPC-Befehl `SetForcedMods` (pro Umgebung eine URL)
3. Wenn ein Spieler dem Server beitritt, lädt sein Client den Mod automatisch von der angegebenen URL herunter
4. Mods sind **flüchtig** – nach einem Serverneustart müssen sie erneut gesetzt werden (das Startup-Script übernimmt das automatisch, siehe unten)

### Vorkonfigurierte Skin-Bibliothek

Das Image wird mit einer vorkonfigurierten Skin-Bibliothek ausgeliefert, die über **50 Skins** für die Stadium-Umgebung enthält. Alle Skins werden von [assets.techniverse.net](https://assets.techniverse.net/tm/skins/) bereitgestellt und sind im RemoteCP-Mods-Plugin als Dropdown-Auswahl verfügbar.

Die Konfiguration befindet sich unter:

| Host-Pfad | Container-Pfad | Beschreibung |
|-----------|----------------|-------------|
| `./data/controlpanel/remotecp/plugins/Mods/settings.xml` | `/var/www/html/remotecp/plugins/Mods/settings.xml` | Mod-Katalog (URLs pro Umgebung) |

> **Hinweis:** Bei bestehenden Installationen (Volumes) wird die alte Standard-`settings.xml` (mit den Original-Beispiel-URLs von blacksunonline.com) beim nächsten Containerstart automatisch durch die neue Version mit den techniverse.net-Skins ersetzt.

### Mods über RemoteCP verwalten

1. RemoteCP öffnen: `http://<host-ip>/remotecp/`
2. Mit SuperAdmin-Zugangsdaten einloggen
3. Im Seitenmenü das **Mods**-Plugin aufrufen
4. Pro Umgebung (Stadium, Island, etc.) einen Skin aus dem Dropdown auswählen
5. "Submit" klicken – der Mod wird sofort auf dem Server aktiviert

### Mods automatisch beim Start forcieren

Über die Umgebungsvariablen `FORCE_MOD_*` kann ein Mod pro Umgebung automatisch bei **jedem** Containerstart gesetzt werden – unabhängig von `FORCE_CONFIG_UPDATE`. Siehe [Umgebungsvariablen – Forced Mods](umgebungsvariablen.md#forced-mods-skins) für Details.

**Beispiel** (in der `.env`-Datei):

```bash
FORCE_MOD_STADIUM=https://assets.techniverse.net/tm/skins/Portal.zip
```

### Eigene Skins hinzufügen

Um eigene Skins in das RemoteCP-Dropdown aufzunehmen, bearbeite die Datei `data/controlpanel/remotecp/plugins/Mods/settings.xml` und füge innerhalb der gewünschten Umgebung einen neuen Eintrag hinzu:

```xml
<Stadium>
    <item name='Mein Skin'>https://example.com/mods/mein_skin.zip</item>
</Stadium>
```

> **Wichtig:** Die ZIP-Datei muss von den Spielern über HTTP/HTTPS erreichbar sein.

## Sicherheit

RemoteCP liefert eine `.htaccess`-Datei mit, die den direkten Zugriff auf XML-Konfigurationsdateien über den Browser verhindert. Apache `mod_rewrite` und `AllowOverride` sind im Image aktiviert, damit dieser Schutz funktioniert.

## Fehlerbehebung

Falls RemoteCP nicht erreichbar ist oder Fehler anzeigt:

1. Prüfe, ob beide Container laufen: `docker ps`
2. MariaDB-Verbindung testen: `docker exec tmserver mysql -h mariadb -u remotecp -p remotecp -e "SELECT 1"`
3. PHP-Debug-Modus aktivieren: `PHP_DISPLAY_ERRORS=true` in der `.env`-Datei setzen
4. Container neu starten: `docker compose restart`
5. PHP-Logs prüfen: `docker exec tmserver cat /var/log/php_errors.log`
6. MariaDB-Logs prüfen: `docker logs tmserver-mariadb`

### Bekannte Hinweise

- RemoteCP ist ein älteres Tool (Version 4.0.3.5) und wurde für PHP 5.x entwickelt, läuft aber mit PHP 7.4
- Die Live-Funktionen (`remoteCP[Live]`) benötigen eine laufende Serververbindung
- **Sicherheitshinweis:** Die Registrierung neuer Benutzer ist standardmäßig aktiviert. Aus Sicherheitsgründen sollte diese deaktiviert werden, damit sich keine unbefugten Nutzer einen Zugang anlegen können. Dazu in der Datei `data/controlpanel/remotecp/xml/settings/settings.xml` den Wert `<register>false</register>` setzen
