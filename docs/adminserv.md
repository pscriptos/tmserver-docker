# AdminServ – Server-Verwaltungsoberfläche

Die Server-Verwaltungsoberfläche basiert auf [AdminServ](https://github.com/Chris92de/AdminServ) und ist über Port 80 erreichbar.

## Einrichtung

1. `http://<host-server-des-containers>` im Browser aufrufen
2. Ein Passwort festlegen – dieses wird als AdminServ-Passwort verwendet
3. TM-Server-Informationen eintragen (Standardwerte können beibehalten werden)
4. `Address` auf `localhost` setzen, um den eingebetteten Server zu verwalten
5. Speichern

## Verbindung zum Server

1. Über den Button „Servers" zur Serverliste navigieren
2. Den gewünschten Server auswählen
3. Admin-Stufe wählen und zugehöriges Passwort eingeben

## Standard-Passwörter

| Stufe | Standard-Passwort |
|-------|-------------------|
| SuperAdmin | `SuperAdmin` |
| Admin | `Admin` |
| User | `User` |

Die Admin-Stufen können unter `http://<host-server-des-containers>/config` geändert werden.

> **Hinweis:** Es wird empfohlen, die Standard-Passwörter über die `.env`-Datei (`SERVER_SA_PASSWORD`, `SERVER_ADM_PASSWORD`) zu ändern. Siehe [Umgebungsvariablen](umgebungsvariablen.md).

## Persistente Speicherung

Alle AdminServ-Daten (Passwort, Server-Einträge, Konfiguration, Logs) werden über einen Bind-Mount (`./data/AdminServ`) persistent auf dem Host gespeichert. Beim ersten Start werden die Dateien automatisch aus dem Image ins Volume kopiert.

| Host-Pfad | Container-Pfad | Beschreibung |
|-----------|----------------|-------------|
| `./data/AdminServ` | `/var/www/html` | Gesamte AdminServ-Installation |

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

### AdminServ komplett zurücksetzen

Falls AdminServ in einen inkonsistenten Zustand geraten ist:

```bash
# AdminServ-Daten auf dem Host löschen
rm -rf ./data/AdminServ/*

# Container neu starten – AdminServ wird frisch initialisiert
docker compose up -d
```
