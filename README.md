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

Das fertige Docker Image kann direkt verwendet werden – kein eigener Build nötig:

```bash
docker compose up -d
```

Das Image wird automatisch aus der Container-Registry geladen:

```
git.techniverse.net/scriptos/trackmania-server:latest
```

> **Tipp:** Alle verfügbaren Tags findest du in der [Container-Registry](https://git.techniverse.net/scriptos/-/packages/container/trackmania-server/). Wenn du das Image lieber selbst bauen möchtest, findest du die Anleitung unter [Schnellstart – Selbst bauen](docs/schnellstart.md#docker-image-selbst-bauen).

### 3. Verwaltungsoberflächen öffnen

- **AdminServ:** `http://<host-ip>/`
- **RemoteCP:** `http://<host-ip>/remotecp/`

> **Hinweis:** Für den Internet-Modus müssen `SERVER_LOGIN` und `SERVER_VALIDATION_KEY` in der `.env`-Datei gesetzt sein. Einen Server-Account kannst du auf [players.trackmaniaforever.com](https://players.trackmaniaforever.com) erstellen. Für den LAN-Modus setze `SERVER_MODE=lan`.

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

Ein herzliches Dankeschön an **[Thomas](https://retronerd.at)** – für seine tatkräftige Unterstützung, sein wertvolles Wissen und seine Mitwirkung an diesem Projekt. Ohne ihn wäre dieses Projekt nicht das, was es heute ist!

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
