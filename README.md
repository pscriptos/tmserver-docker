# tmserver-docker

Ein vollständiges Docker-Setup für einen **TrackMania Nations Forever**-Server – inklusive Web-Verwaltung und Server-Controller:

- **TrackMania Dedicated Server** – der eigentliche Spielserver für Internet- oder LAN-Betrieb
- **[XAseco](docs/xaseco.md)** – Server-Controller, der lokale Rekorde, Dedimania-Weltrekorde, Karma/Votes und eine Track-Jukebox direkt im Spielchat verwaltet
- **[AdminServ](docs/adminserv.md)** – Web-Oberfläche zur komfortablen Verwaltung und Konfiguration des Servers
- **[RemoteCP](docs/remotecp.md)** – alternative Web-Verwaltungsoberfläche mit eigenem Login- und Benutzersystem

Alle Komponenten laufen in einem einzigen Container und werden über Umgebungsvariablen konfiguriert.

> **Hinweis:** Dieses Projekt ist ein Fork von [lduriez/tmserver-docker](https://github.com/lduriez/tmserver-docker?tab=readme-ov-file).

Der Server unterstützt sowohl den **Internet-Dedicated-Modus** (Standard) als auch den **LAN-Dedicated-Modus**.

## Schnellstart

### 1. Umgebungsvariablen einrichten

```bash
cp .env.example .env
```

Passe die Werte in der `.env`-Datei an deine Umgebung an (Passwörter, Masterserver-Account, etc.).

> **⚠ Sicherheitshinweis:** Die `.env.example` enthält **vorgenerierte Beispiel-Passwörter**. Diese dienen nur als Platzhalter und sind öffentlich einsehbar! **Ändere unbedingt alle Passwörter**, bevor du den Server produktiv einsetzt.

### 2. Server starten

```bash
docker compose up -d --build
```

### 3. Verwaltungsoberflächen öffnen

- **AdminServ:** `http://<host-ip>/`
- **RemoteCP:** `http://<host-ip>/remotecp/`

> **Hinweis:** Für den Internet-Modus müssen `SERVER_LOGIN` und `SERVER_VALIDATION_KEY` in der `.env`-Datei gesetzt sein. Einen Server-Account kannst du auf [players.trackmaniaforever.com](https://players.trackmaniaforever.com) erstellen. Für den LAN-Modus setze `SERVER_MODE=lan`.

## Projektstruktur

```
├── assets/
│   ├── bin/                         # Binaries und Startscript
│   │   ├── AdminServ_v2.1.1.zip    # AdminServ Web-UI
│   │   ├── remoteCP_v4.0.3.5.zip   # RemoteCP Web-UI
│   │   ├── xaseco_v1.16.zip         # XAseco Server-Controller
│   │   ├── RunTrackmaniaServer.sh   # Container-Startscript
│   │   └── TrackmaniaServer_*.zip   # Trackmania Server Binary
│   ├── config/
│       ├── custom_game_settings.txt # MatchSettings (Spielmodus, Map-Rotation)
│       └── dedicated_cfg.txt        # Server-Config-Template (mit Platzhaltern)
│   └── db/
│       └── init-xaseco-db.sh        # MariaDB Init-Script fuer XAseco-DB
├── docs/                            # Dokumentation
├── docker-compose.yml               # Docker Compose Konfiguration
├── Dockerfile                       # Docker Build-Definition
├── .env.example                     # Vorlage fuer Umgebungsvariablen
├── .env                             # Lokale Umgebungsvariablen (nicht im Git!)
└── data/                            # Persistente Daten (zur Laufzeit)
    ├── gamedata/                    # TM-Server-Daten
    ├── controlpanel/                # AdminServ + RemoteCP
    ├── xaseco/                      # XAseco-Konfiguration und Logs
    └── mariadb/                     # MariaDB-Datenbankdateien
```

## Dokumentation

Die vollständige Dokumentation befindet sich im Ordner [`docs/`](docs/README.md):

- [Schnellstart](docs/schnellstart.md) – Erste Schritte und minimale Konfiguration
- [Konfiguration](docs/konfiguration.md) – Persistente Serverkonfiguration (dedicated_cfg.txt)
- [Umgebungsvariablen](docs/umgebungsvariablen.md) – Alle verfügbaren Umgebungsvariablen
- [Server-Modi](docs/server-modi.md) – LAN- und Internet-Dedicated-Modus
- [AdminServ](docs/adminserv.md) – Einrichtung der Server-Verwaltungsoberfläche
- [RemoteCP](docs/remotecp.md) – Alternative Server-Verwaltungsoberfläche
- [XAseco](docs/xaseco.md) – Server-Controller für Rekorde, Karma und Jukebox
- [Ports](docs/ports.md) – Freigegebene Ports und deren Verwendung

## Danksagung

Danke an **Thomas** ([retronerd.at](https://retronerd.at)), dass er mir sein Wissen zur Verfügung gestellt hat und dass er hier im Projekt mitgewirkt hat.

## Spiegelung

Dieses Repository wird von **Gitea** auf **GitHub** gespiegelt. Das Master-Repository befindet sich auf Gitea:

- **Gitea (Master):** [git.techniverse.net/scriptos/tmserver-docker](https://git.techniverse.net/scriptos/tmserver-docker.git)
- **GitHub (Spiegel):** [github.com/pscriptos/tmserver-docker](https://github.com/pscriptos/tmserver-docker.git)

---

📝 **Blog:** [www.cleveradmin.de](https://www.cleveradmin.de)  
🌐 **Webseite:** [www.patrick-asmus.de](https://www.patrick-asmus.de)  
📧 **E-Mail:** [support@techniverse.net](mailto:support@techniverse.net)  

<p align="center">
  <img src="https://assets.techniverse.net/f1/git/graphics/gray0-catonline.svg" alt="">
</p>

<p align="center">
<img src="https://assets.techniverse.net/f1/logos/small/license.png" alt="License" width="15" height="15"> <a href="./LICENSE">License</a> | <img src="https://assets.techniverse.net/f1/logos/small/matrix2.svg" alt="Matrix" width="15" height="15"> <a href="https://matrix.to/#/#community:techniverse.net">Matrix</a> | <img src="https://assets.techniverse.net/f1/logos/small/mastodon2.svg" alt="Mastodon" width="15" height="15"> <a href="https://social.techniverse.net/@donnerwolke">Mastodon</a>
</p>
