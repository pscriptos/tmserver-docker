# Dokumentation

Übersicht aller verfügbaren Dokumentationen für den Trackmania Nations Forever Docker Server.

> **Wichtig:** Vor dem ersten Start muss eine `.env`-Datei aus der Vorlage erstellt werden: `cp .env.example .env`

> **⚠ Sicherheitshinweis:** Die `.env.example` enthält **vorgenerierte Beispiel-Passwörter**. Diese dienen nur als Platzhalter und sind öffentlich einsehbar! **Ändere unbedingt alle Passwörter** in der `.env`-Datei, bevor du den Server produktiv einsetzt.

| Dokument | Beschreibung |
|----------|-------------|
| [Schnellstart](schnellstart.md) | Erste Schritte und minimale Konfiguration |
| [Konfiguration](konfiguration.md) | Persistente Serverkonfiguration (dedicated_cfg.txt), Graceful Shutdown |
| [Umgebungsvariablen](umgebungsvariablen.md) | Alle verfügbaren Umgebungsvariablen |
| [Server-Modi](server-modi.md) | LAN- und Internet-Dedicated-Modus |
| [AdminServ](adminserv.md) | Einrichtung der Server-Verwaltungsoberfläche |
| [RemoteCP](remotecp.md) | Alternative Server-Verwaltungsoberfläche (inkl. Mods/Skins) |
| [XAseco](xaseco.md) | Server-Controller für Rekorde, Karma und Jukebox |
| [IP-Watcher](ip-watcher.md) | Automatischer Neustart bei IP-Wechsel |
| [Ports](ports.md) | Freigegebene Ports und deren Verwendung |
| [Update](update.md) | Bestehende Installation aktualisieren |

## Projektstruktur

```
├── assets/
│   ├── bin/                                     # Binaries und Startscript
│   │   ├── AdminServ_v2.1.1.zip                 # AdminServ Web-UI
│   │   ├── remoteCP_v4.0.3.5.zip                # RemoteCP Web-UI
│   │   ├── RunTrackmaniaServer.sh               # Container-Startscript
│   │   ├── TrackmaniaServer_2011-02-21.zip      # Trackmania Server Binary
│   │   ├── WatchPublicIP.sh                     # IP-Watcher-Script
│   │   └── xaseco_v1.16.zip                     # XAseco Server-Controller
│   ├── config/
│   │   ├── adminserv/                           # AdminServ-Konfiguration
│   │   │   ├── get_matchset_mapimport.php       # MatchSet Map-Import Script
│   │   │   └── maps-creatematchset.php          # MatchSet-Erstellung Script
│   │   ├── custom_game_settings.txt             # MatchSettings (Spielmodus, Map-Rotation)
│   │   ├── dedicated_cfg.txt                    # Server-Config-Template (mit Platzhaltern)
│   │   ├── logrotate.conf                       # Log-Rotation-Konfiguration (groessenbasiert)
│   │   ├── remotecp/
│   │   │   └── plugins/
│   │   │       ├── CustomPoints/
│   │   │       │   └── index.php                # CustomPoints-Plugin fuer RemoteCP
│   │   │       └── Mods/
│   │   │           ├── index.php                # Mods-Plugin fuer RemoteCP
│   │   │           └── settings.xml             # Skin-Bibliothek (techniverse.net)
│   │   └── xaseco/
│   │       └── teamspeak3.xml                   # TeamSpeak3-Konfiguration fuer XAseco
│   └── db/
│       └── init-xaseco-db.sh                    # MariaDB Init-Script fuer XAseco-DB
├── .gitea/
│   └── workflows/
│       └── docker-publish.yml                  # CI/CD: Docker Image Build & Push bei neuem Release-Tag
├── docs/                                        # Dokumentation (siehe Tabelle oben)
│   └── update.md                                    # Update-Anleitung
├── docker-compose.yml                           # Docker Compose Konfiguration
├── Dockerfile                                   # Docker Build-Definition
├── .dockerignore                                # Docker-Ignore-Regeln
├── .env.example                                 # Vorlage fuer Umgebungsvariablen
├── .env                                         # Lokale Umgebungsvariablen (nicht im Git!)
├── .gitattributes                               # Git-Attribut-Konfiguration
├── .gitignore                                   # Git-Ignore-Regeln
├── LICENSE                                      # Lizenz
├── README.md                                    # Projektbeschreibung
└── data/                                        # Persistente Daten (zur Laufzeit)
    ├── gamedata/                                # TM-Server-Daten
    ├── controlpanel/                            # AdminServ + RemoteCP
    ├── xaseco/                                  # XAseco-Konfiguration und Logs
    └── mariadb/                                 # MariaDB-Datenbankdateien
```
