# XAseco

XAseco ist ein Server-Controller für TrackMania Nations Forever. Er verwaltet lokale Rekorde, Dedimania-Weltrekorde, Karma/Votes, eine Track-Jukebox und vieles mehr direkt im Spielchat.

Im Container wird die modifizierte Version **XAseco 1.16** verwendet, die für PHP 7.x angepasst wurde (Patches von Bueddel, Xymph, undef.de und reaby).

## Funktionsweise

XAseco verbindet sich über XML-RPC mit dem TrackMania-Server und reagiert auf Spielereignisse (neue Rekorde, Spieler-Connects, Chat-Befehle usw.). Die Daten werden in einer eigenen MySQL-Datenbank gespeichert.

## TeamSpeak 3 Integration

XAseco enthält ein Plugin (`plugin.teamspeak3.php`), das im Spiel ein Widget mit den aktuell verbundenen TeamSpeak-3-Nutzern anzeigt. Das Plugin ist **standardmäßig aktiviert** und verwendet ein eigenes Gateway, das im Container mitgeliefert wird (das Original-Gateway des Plugin-Entwicklers ist nicht mehr verfügbar).

### TS3-Server konfigurieren

Die Konfiguration erfolgt über die Datei `data/xaseco/teamspeak3.xml`. Dort kann der eigene TeamSpeak-3-Server eingetragen werden:

```xml
<?xml version="1.0" encoding="utf-8"?>
<settings>
        <!-- Server Configuration, can be address or ip -->
        <server>ts3.techniverse.net</server>
        <serverid>1</serverid>
        <serverport>9987</serverport>
        <queryport>10011</queryport>

        <!-- Channel & Update Settings -->
        <defaultchannel></defaultchannel>
        <subchannel></subchannel>
        <channelpassword></channelpassword>
        <update_interval>30</update_interval>

        <!-- Helpers and images -->
        <helperURL>http://assets.techniverse.net/tm/ts3gateway/gateway3.html</helperURL>
        <logoURL>http://assets.techniverse.net/tm/ts3gateway/ts3logo.jpg</logoURL>

        <!-- Widget position -->
        <posx>-64</posx>
        <posy>45</posy>
</settings>
```

| Feld | Beschreibung |
|------|-------------|
| `server` | Hostname oder IP des TS3-Servers |
| `serverid` | Virtuelle-Server-ID (meist `1`) |
| `serverport` | Voice-Port des TS3-Servers (Standard: `9987`) |
| `queryport` | ServerQuery-Port (Standard: `10011`) |
| `defaultchannel` | Standard-Channel (leer = Server-Default) |
| `subchannel` | Sub-Channel (optional) |
| `channelpassword` | Channel-Passwort (optional) |
| `update_interval` | Aktualisierungsintervall in Sekunden |
| `helperURL` | URL zur Gateway-HTML-Seite (nicht ändern) |
| `logoURL` | URL zum TS3-Logo im Widget (nicht ändern) |
| `posx` / `posy` | Widget-Position im Spiel |

> **Hinweis:** Standardmäßig ist der TS3-Server `ts3.techniverse.net` vorkonfiguriert. Zum Anpassen einfach nach dem ersten Start die Datei `data/xaseco/teamspeak3.xml` bearbeiten. Die Felder `helperURL` und `logoURL` verweisen auf das mitgelieferte Gateway und sollten nicht geändert werden.

## Konfiguration

Die Konfiguration erfolgt ausschließlich über Umgebungsvariablen in der `.env`-Datei. Beim **ersten Start** (leeres XAseco-Volume) werden die Werte automatisch in die XML-Konfigurationsdateien eingetragen.

### Erforderliche Variablen

| Variable | Beschreibung | Standard |
|----------|-------------|----------|
| `XASECO_MASTERADMIN_LOGIN` | Dein Spieler-Login (MasterAdmin mit allen Rechten) | *(muss gesetzt werden)* |
| `XASECO_DB_PASSWORD` | Passwort für die XAseco-Datenbank | *(muss gesetzt werden)* |

### Optionale Variablen

| Variable | Beschreibung | Standard |
|----------|-------------|----------|
| `XASECO_ENABLED` | XAseco aktivieren/deaktivieren | `true` |
| `XASECO_DB_HOST` | Hostname des Datenbankservers | `mariadb` |
| `XASECO_DB_NAME` | Name der XAseco-Datenbank | `xaseco` |
| `XASECO_DB_USER` | Datenbank-Benutzername | `xaseco` |
| `XASECO_DEDIMANIA_NATION` | Dedimania-Nation ([IOC-Code](https://en.wikipedia.org/wiki/List_of_IOC_country_codes), z.B. `DEU`, `AUT`, `CHE`) | `DEU` |
| `XASECO_HEALTHCHECK` | Automatische Überwachung und Neustart bei Absturz | `true` |
| `XASECO_HEALTHCHECK_INTERVAL` | Prüfintervall des Healthchecks in Sekunden | `60` |

### Automatisch übernommene Variablen

Diese Werte werden aus der bestehenden Server-Konfiguration übernommen und müssen **nicht** separat gesetzt werden:

| Quelle | Verwendung in XAseco |
|--------|---------------------|
| `SERVER_SA_PASSWORD` | SuperAdmin-Passwort für die XML-RPC-Verbindung |
| `SERVER_XMLRPC_PORT` | XML-RPC-Port für die Verbindung zum TM-Server |
| `SERVER_LOGIN` | Dedimania Server-Login |
| `SERVER_LOGIN_PASSWORD` | Dedimania Server-Passwort |

## Datenbank

XAseco verwendet eine **eigene Datenbank** im selben MariaDB-Container. Die Datenbank und der Benutzer werden beim ersten Start des MariaDB-Containers automatisch erstellt (über ein Init-Script).

Das Datenbankschema (drei Tabellen-Dateien) wird beim ersten Start des tmserver-Containers automatisch importiert.

### Manueller Zugriff

Falls nötig, kann die XAseco-Datenbank über den MariaDB-Root-Zugang administriert werden:

```bash
docker exec -it tmserver-mariadb mysql -u root -p
```

### Nachträgliche Installation (bestehende MariaDB)

Das Init-Script (`assets/db/init-xaseco-db.sh`) wird von MariaDB nur beim **allerersten Start** (leeres `data/mariadb/`-Volume) ausgeführt. Wenn der MariaDB-Container bereits Daten enthält (z.B. weil er zuvor ohne XAseco lief), muss die Datenbank **einmalig manuell** erstellt werden:

```bash
docker exec -it tmserver-mariadb mysql -u root -p -e "
  CREATE DATABASE IF NOT EXISTS xaseco CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
  CREATE USER IF NOT EXISTS 'xaseco'@'%' IDENTIFIED BY 'DEIN_XASECO_DB_PASSWORT';
  GRANT ALL PRIVILEGES ON xaseco.* TO 'xaseco'@'%';
  FLUSH PRIVILEGES;"
```

Ersetze `DEIN_XASECO_DB_PASSWORT` durch den Wert von `XASECO_DB_PASSWORD` aus der `.env`-Datei. Das Tabellen-Schema wird anschließend beim nächsten Container-Start automatisch importiert, sofern das XAseco-Volume noch leer ist.

## Admin-System

XAseco kennt drei Berechtigungsstufen:

| Stufe | Beschreibung |
|-------|-------------|
| **MasterAdmin** | Volle Kontrolle (wird über `XASECO_MASTERADMIN_LOGIN` gesetzt) |
| **Admin** | Erweiterte Befehle (ebenfalls über `XASECO_MASTERADMIN_LOGIN` gesetzt) |
| **Operator** | Eingeschränkte Moderationsbefehle |

Weitere Admins/Operatoren können nach dem ersten Start manuell in `data/xaseco/adminops.xml` eingetragen werden.

## Persistente Daten

Alle XAseco-Daten werden im Volume `./data/xaseco/` gespeichert:

- Konfigurationsdateien (`config.xml`, `localdatabase.xml`, `dedimania.xml`, ...)
- Log-Datei (`aseco.log`)
- Admin-/Operator-Listen (`adminops.xml`)

## Deaktivieren

XAseco kann über die `.env`-Datei deaktiviert werden:

```env
XASECO_ENABLED=false
```

Der TrackMania-Server läuft dann ohne Server-Controller.

## Healthcheck / Watchdog

XAseco wird automatisch durch einen Watchdog-Prozess überwacht. Dieser erkennt Abstürze und verlorene Verbindungen (z.B. wenn das Overlay im Spiel verschwindet) und startet XAseco selbstständig neu.

### Funktionsweise

Der Watchdog prüft regelmäßig (Standard: alle 60 Sekunden):

1. **PID-Check:** Läuft der XAseco-PHP-Prozess noch?
2. **Log-Check:** Enthält das XAseco-Log fatale Fehler oder Verbindungsabbrüche?
3. **XMLRPC-Check:** Ist der TM-Server noch erreichbar?

Bei erkannten Problemen wird XAseco automatisch beendet und neu gestartet. Crash-Logs werden zur Fehleranalyse unter `data/xaseco/aseco_crash_<TIMESTAMP>.log` gesichert (max. 5 Dateien).

### Konfiguration

| Variable | Beschreibung | Standard |
|----------|-------------|----------|
| `XASECO_HEALTHCHECK` | Watchdog aktivieren/deaktivieren | `true` |
| `XASECO_HEALTHCHECK_INTERVAL` | Prüfintervall in Sekunden | `60` |

```env
# Healthcheck deaktivieren
XASECO_HEALTHCHECK=false

# Prüfintervall auf 30 Sekunden verkürzen
XASECO_HEALTHCHECK_INTERVAL=30
```

> **Hinweis:** Der Watchdog ist standardmäßig aktiviert und erfordert keine zusätzliche Konfiguration. Bei bestehenden Installationen wird er nach dem nächsten Image-Update automatisch aktiv.

## Logs

Die XAseco-Logdatei befindet sich unter:

```
./data/xaseco/aseco.log
```

Bei Problemen ist dies die erste Anlaufstelle für die Fehlersuche.

> **Hinweis:** Die XAseco-Logdatei wird automatisch per logrotate rotiert (max. 10 MB pro Datei, 5 rotierte Dateien). Alte Logs werden komprimiert als `aseco.log.1.gz`, `aseco.log.2.gz` usw. aufbewahrt. Siehe [Konfiguration – Log-Rotation](konfiguration.md#log-rotation).

## Chat-Befehle

Nachfolgend eine Übersicht der wichtigsten Befehle, die im Spielchat verfügbar sind. Eine vollständige Liste aller Befehle findest du in der offiziellen Dokumentation unter: https://docs.xaseco.org/commands.php

### Hilfe & Info

| Befehl | Beschreibung |
|--------|-------------|
| `/help` | Zeigt alle verfügbaren Befehle |
| `/helpall` | Zeigt ausführliche Hilfe zu allen Befehlen |
| `/xaseco` | Zeigt Infos über die XAseco-Version |
| `/server` | Zeigt Infos über den Server |
| `/plugins` | Zeigt Liste der aktiven Plugins |
| `/time` | Zeigt aktuelle Serverzeit und Datum |

### Rekorde & Statistiken

| Befehl | Beschreibung |
|--------|-------------|
| `/recs` | Zeigt alle lokalen Rekorde auf der aktuellen Strecke |
| `/recs pb` | Zeigt deine persönliche Bestzeit |
| `/recs new` | Zeigt neu gefahrene Rekorde |
| `/recs live` | Zeigt Rekorde der Online-Spieler |
| `/pb` | Zeigt deine persönliche Bestzeit auf der aktuellen Strecke |
| `/dedirecs` | Zeigt Dedimania-Rekorde auf der aktuellen Strecke |
| `/dedipb` | Zeigt deine persönliche Dedimania-Bestzeit |
| `/dedistats` | Zeigt Dedimania-Streckenstatistiken |
| `/best` | Zeigt deine besten Rekorde |
| `/worst` | Zeigt deine schlechtesten Rekorde |
| `/summary` | Zeigt eine Zusammenfassung aller deiner Rekorde |
| `/stats` | Zeigt Statistiken des aktuellen Spielers |
| `/wins` | Zeigt Siege des aktuellen Spielers |

### Rankings & Toplisten

| Befehl | Beschreibung |
|--------|-------------|
| `/rank` | Zeigt deinen aktuellen Serverrang |
| `/nextrank` | Zeigt den nächst besser platzierten Spieler |
| `/top10` | Zeigt die 10 bestplatzierten Spieler |
| `/top100` | Zeigt die 100 bestplatzierten Spieler |
| `/topwins` | Zeigt die 100 siegreichsten Spieler |
| `/toprecs` | Zeigt Top 100 der Rekord-Halter |
| `/topsums` | Zeigt Top 100 der Top-3-Rekord-Halter |
| `/active` | Zeigt die 100 aktivsten Spieler |
| `/topclans` | Zeigt die 10 bestplatzierten Clans |

### Strecken & Jukebox

| Befehl | Beschreibung |
|--------|-------------|
| `/track` | Zeigt Infos über die aktuelle Strecke |
| `/nextmap` | Zeigt den Namen der nächsten Strecke |
| `/playtime` | Zeigt, wie lange die aktuelle Strecke läuft |
| `/list` | Listet Strecken auf dem Server (siehe `/list help`) |
| `/list nofinish` | Strecken, auf denen du keinen Rang hast |
| `/list newest` | Die neuesten Strecken |
| `/list <name>` | Suche nach Strecken- oder Autorennamen |
| `/jukebox` | Track-Jukebox (siehe `/jukebox help`) |
| `/jukebox list` | Zeigt kommende Strecken |
| `/jukebox <#>` | Fügt Strecke Nr. `<#>` aus `/list` hinzu |
| `/jukebox drop` | Entfernt deine hinzugefügte Strecke |
| `/add <ID>` | Fügt eine Strecke direkt von TMX hinzu |
| `/history` | Zeigt die 10 zuletzt gespielten Strecken |

### Karma & Voting

| Befehl | Beschreibung |
|--------|-------------|
| `/karma` | Zeigt Karma der aktuellen Strecke |
| `/++` | Positive Bewertung für die aktuelle Strecke |
| `/--` | Negative Bewertung für die aktuelle Strecke |
| `/helpvote` | Zeigt Infos zum Chat-Voting-System |
| `/endround` | Startet Vote zum Beenden der aktuellen Runde |
| `/replay` | Startet Vote zum Wiederholen der Strecke |
| `/skip` | Startet Vote zum Überspringen der Strecke |
| `/kick` | Startet Vote zum Kicken eines Spielers |
| `/y` | Stimmt mit Ja bei einem laufenden Vote |
| `/cancel` | Bricht deinen aktuellen Vote ab |

### Kommunikation

| Befehl | Beschreibung |
|--------|-------------|
| `/pm <login> <msg>` | Sendet eine private Nachricht |
| `/pmlog` | Zeigt Verlauf deiner privaten Nachrichten |
| `/chatlog` | Zeigt Verlauf der letzten Chat-Nachrichten |
| `/me` | Drückt eine Aktion/Emotion aus |
| `/hi` | Sendet eine Hallo-Nachricht an alle |
| `/bye` | Sendet eine Tschüss-Nachricht an alle |
| `/gg` | Sendet "Good Game" an alle |
| `/n1` | Sendet "Nice One" an alle |
| `/brb` | Sendet "Be Right Back" an alle |
| `/afk` | Sendet "Away From Keyboard" an alle |

### Spieleroptionen

| Befehl | Beschreibung |
|--------|-------------|
| `/settings` | Zeigt deine persönlichen Einstellungen |
| `/cps` | Setzt Checkpoint-Tracking für lokale Rekorde |
| `/dedicps` | Setzt Checkpoint-Tracking für Dedimania-Rekorde |
| `/mute <login>` | Chat eines Spielers stummschalten |
| `/unmute <login>` | Stummschaltung aufheben |
| `/mutelist` | Zeigt Liste der stummgeschalteten Spieler |
| `/players` | Zeigt aktuelle Spieler-Liste (Nicks/Logins) |
| `/ranks` | Zeigt Liste der Online-Ränge |
| `/bootme` | Kickt dich selbst vom Server |

### Admin-Befehle (`/admin`)

Diese Befehle sind nur für Admins und MasterAdmins verfügbar.

| Befehl | Beschreibung |
|--------|-------------|
| `/admin help` | Zeigt alle Admin-Befehle |
| `/admin helpall` | Zeigt ausführliche Hilfe zu allen Admin-Befehlen |

**Server-Einstellungen:**

| Befehl | Beschreibung |
|--------|-------------|
| `/admin setservername <name>` | Ändert den Servernamen |
| `/admin setpwd <pwd>` | Ändert das Spieler-Passwort |
| `/admin setspecpwd <pwd>` | Ändert das Zuschauer-Passwort |
| `/admin setmaxplayers <#>` | Setzt maximale Spieleranzahl |
| `/admin setmaxspecs <#>` | Setzt maximale Zuschauerzahl |
| `/admin setgamemode <mode>` | Setzt Spielmodus (ta/rounds/team/laps/stunts/cup) |

**Strecken-Verwaltung:**

| Befehl | Beschreibung |
|--------|-------------|
| `/admin nextmap` | Erzwingt nächste Strecke |
| `/admin restartmap` | Startet aktuelle Strecke neu |
| `/admin replaymap` | Wiederholt aktuelle Strecke (via Jukebox) |
| `/admin endround` | Erzwingt Ende der aktuellen Runde |
| `/admin add <ID>` | Fügt Strecke von TMX hinzu |
| `/admin addlocal <datei>` | Fügt lokale Strecke hinzu |
| `/admin remove <#>` | Entfernt Strecke aus der Rotation |
| `/admin erasethis` | Entfernt aktuelle Strecke und löscht Datei |
| `/admin shuffle` | Mischt die Streckenliste zufällig |
| `/admin writetracklist` | Speichert aktuelle Streckenliste |
| `/admin readtracklist` | Lädt Streckenliste aus Datei |

**Jukebox:**

| Befehl | Beschreibung |
|--------|-------------|
| `/admin dropjukebox <#>` | Entfernt eine Strecke aus der Jukebox |
| `/admin clearjukebox` | Leert die gesamte Jukebox |
| `/admin pass` | Genehmigt einen laufenden Vote |
| `/admin cancel` | Bricht einen laufenden Vote ab |

**Spieler-Moderation:**

| Befehl | Beschreibung |
|--------|-------------|
| `/admin warn <login>` | Sendet eine Warnung an einen Spieler |
| `/admin kick <login>` | Kickt einen Spieler vom Server |
| `/admin kickghost <login>` | Kickt einen Ghost-Spieler |
| `/admin ban <login>` | Bannt einen Spieler |
| `/admin unban <login>` | Entbannt einen Spieler |
| `/admin black <login>` | Setzt einen Spieler auf die Blacklist |
| `/admin unblack <login>` | Entfernt einen Spieler von der Blacklist |
| `/admin mute <login>` | Schaltet einen Spieler global stumm |
| `/admin unmute <login>` | Hebt globale Stummschaltung auf |
| `/admin forcespec <login>` | Erzwingt Zuschauer-Modus |
| `/admin forceteam <login>` | Erzwingt Team-Zuordnung (Blue/Red) |

**Admin-Verwaltung:**

| Befehl | Beschreibung |
|--------|-------------|
| `/admin addadmin <login>` | Fügt einen neuen Admin hinzu |
| `/admin removeadmin <login>` | Entfernt einen Admin |
| `/admin addop <login>` | Fügt einen neuen Operator hinzu |
| `/admin removeop <login>` | Entfernt einen Operator |
| `/admin listmasters` | Zeigt MasterAdmin-Liste |
| `/admin listadmins` | Zeigt Admin-Liste |
| `/admin listops` | Zeigt Operator-Liste |

**Rekorde & System:**

| Befehl | Beschreibung |
|--------|-------------|
| `/admin delrec <#>` | Löscht einen bestimmten Rekord auf der aktuellen Strecke |
| `/admin wall <msg>` | Zeigt Popup-Nachricht für alle Spieler |
| `/admin pm <msg>` | Sendet private Nachricht an alle Admins |
| `/admin server` | Zeigt detaillierte Server-Einstellungen |
| `/admin shutdown` | Fährt XAseco herunter |
| `/admin shutdownall` | Fährt Server und XAseco herunter |

> **Tipp:** Eine vollständige Referenz aller Befehle (inkl. `/jfreu`-Befehle für erweiterte Moderation) findest du unter: https://docs.xaseco.org/commands.php
