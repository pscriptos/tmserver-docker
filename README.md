# tmserver-docker

Trackmania Nations Forever Docker Server

> **Hinweis:** Dieses Projekt ist ein Fork von [lduriez/tmserver-docker](https://github.com/lduriez/tmserver-docker?tab=readme-ov-file).

Der Server unterstützt sowohl den **Internet-Dedicated-Modus** (Standard) als auch den **LAN-Dedicated-Modus**.

## Schnellstart

### 1. Umgebungsvariablen einrichten

```bash
cp .env.example .env
```

Passe die Werte in der `.env`-Datei an deine Umgebung an (Passwörter, Masterserver-Account, etc.).

### 2. Server starten

```bash
docker compose up -d --build
```

### 3. AdminServ öffnen

Die Verwaltungsoberfläche ist unter `http://<host-ip>` erreichbar.

> **Hinweis:** Für den Internet-Modus müssen `SERVER_LOGIN` und `SERVER_VALIDATION_KEY` in der `.env`-Datei gesetzt sein. Einen Server-Account kannst du auf [players.trackmaniaforever.com](https://players.trackmaniaforever.com) erstellen. Für den LAN-Modus setze `SERVER_MODE=lan`.

## Projektstruktur

```
├── assets/
│   ├── bin/                         # Binaries und Startscript
│   │   ├── AdminServ_v2.1.1.zip    # AdminServ Web-UI
│   │   ├── RunTrackmaniaServer.sh   # Container-Startscript
│   │   └── TrackmaniaServer_*.zip   # Trackmania Server Binary
│   └── config/
│       ├── custom_game_settings.txt # MatchSettings (Spielmodus, Map-Rotation)
│       └── dedicated_cfg.txt        # Server-Config-Template (mit Platzhaltern)
├── docs/                            # Dokumentation
├── docker-compose.yml               # Docker Compose Konfiguration
├── Dockerfile                       # Docker Build-Definition
├── .env.example                     # Vorlage fuer Umgebungsvariablen
├── .env                             # Lokale Umgebungsvariablen (nicht im Git!)
└── data/GameData/                   # Persistente Serverdaten (zur Laufzeit)
```

## Dokumentation

Die vollständige Dokumentation befindet sich im Ordner [`docs/`](docs/README.md):

- [Schnellstart](docs/schnellstart.md) – Erste Schritte und minimale Konfiguration
- [Konfiguration](docs/konfiguration.md) – Persistente Serverkonfiguration (dedicated_cfg.txt)
- [Umgebungsvariablen](docs/umgebungsvariablen.md) – Alle verfügbaren Umgebungsvariablen
- [Server-Modi](docs/server-modi.md) – LAN- und Internet-Dedicated-Modus
- [AdminServ](docs/adminserv.md) – Einrichtung der Server-Verwaltungsoberfläche
- [Ports](docs/ports.md) – Freigegebene Ports und deren Verwendung

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
