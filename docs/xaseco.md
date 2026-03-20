# XAseco

XAseco ist ein Server-Controller für TrackMania Nations Forever. Er verwaltet lokale Rekorde, Dedimania-Weltrekorde, Karma/Votes, eine Track-Jukebox und vieles mehr direkt im Spielchat.

Im Container wird die modifizierte Version **XAseco 1.16** verwendet, die für PHP 7.x angepasst wurde (Patches von Bueddel, Xymph, undef.de und reaby).

## Funktionsweise

XAseco verbindet sich über XML-RPC mit dem TrackMania-Server und reagiert auf Spielereignisse (neue Rekorde, Spieler-Connects, Chat-Befehle usw.). Die Daten werden in einer eigenen MySQL-Datenbank gespeichert.

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

## Logs

Die XAseco-Logdatei befindet sich unter:

```
./data/xaseco/aseco.log
```

Bei Problemen ist dies die erste Anlaufstelle für die Fehlersuche.

## Wichtige Chat-Befehle

| Befehl | Beschreibung |
|--------|-------------|
| `/helpadmin` | Admin-Befehle anzeigen |
| `/recs` | Lokale Rekorde anzeigen |
| `/dedirecs` | Dedimania-Rekorde anzeigen |
| `/jukebox` | Track-Jukebox öffnen |
| `/stats` | Spieler-Statistiken anzeigen |
| `/admin help` | Alle Admin-Befehle |
