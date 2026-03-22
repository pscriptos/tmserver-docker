# Dokumentation

Übersicht aller verfügbaren Dokumentationen für den Trackmania Nations Forever Docker Server.

> **Wichtig:** Vor dem ersten Start muss eine `.env`-Datei aus der Vorlage erstellt werden: `cp .env.example .env`

> **⚠ Sicherheitshinweis:** Die `.env.example` enthält **vorgenerierte Beispiel-Passwörter**. Diese dienen nur als Platzhalter und sind öffentlich einsehbar! **Ändere unbedingt alle Passwörter** in der `.env`-Datei, bevor du den Server produktiv einsetzt.

| Dokument | Beschreibung |
|----------|-------------|
| [Schnellstart](schnellstart.md) | Erste Schritte und minimale Konfiguration |
| [Konfiguration](konfiguration.md) | Persistente Serverkonfiguration (dedicated_cfg.txt) |
| [Umgebungsvariablen](umgebungsvariablen.md) | Alle verfügbaren Umgebungsvariablen |
| [Server-Modi](server-modi.md) | LAN- und Internet-Dedicated-Modus |
| [AdminServ](adminserv.md) | Einrichtung der Server-Verwaltungsoberfläche |
| [RemoteCP](remotecp.md) | Alternative Server-Verwaltungsoberfläche |
| [XAseco](xaseco.md) | Server-Controller für Rekorde, Karma und Jukebox |
| [Ports](ports.md) | Freigegebene Ports und deren Verwendung |

## Projektstruktur

```
├── assets/
│   ├── bin/                                     # Binaries und Startscript
│   │   ├── AdminServ_v2.1.1.zip                # AdminServ Web-UI
│   │   ├── remoteCP_v4.0.3.5.zip               # RemoteCP Web-UI
│   │   ├── xaseco_v1.16.zip                     # XAseco Server-Controller
│   │   ├── RunTrackmaniaServer.sh               # Container-Startscript
│   │   └── TrackmaniaServer_*.zip               # Trackmania Server Binary
│   ├── config/
│   │   ├── custom_game_settings.txt             # MatchSettings (Spielmodus, Map-Rotation)
│   │   ├── dedicated_cfg.txt                    # Server-Config-Template (mit Platzhaltern)
│   │   └── remotecp/
│   │       └── plugins/
│   │           └── CustomPoints/
│   │               └── index.php                # CustomPoints-Plugin fuer RemoteCP
│   └── db/
│       └── init-xaseco-db.sh                    # MariaDB Init-Script fuer XAseco-DB
├── docs/                                        # Dokumentation
├── docker-compose.yml                           # Docker Compose Konfiguration
├── Dockerfile                                   # Docker Build-Definition
├── .env.example                                 # Vorlage fuer Umgebungsvariablen
├── .env                                         # Lokale Umgebungsvariablen (nicht im Git!)
├── LICENSE                                      # Lizenz
├── README.md                                    # Projektbeschreibung
└── data/                                        # Persistente Daten (zur Laufzeit)
    ├── gamedata/                                # TM-Server-Daten
    ├── controlpanel/                            # AdminServ + RemoteCP
    ├── xaseco/                                  # XAseco-Konfiguration und Logs
    └── mariadb/                                 # MariaDB-Datenbankdateien
```
