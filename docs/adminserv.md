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
