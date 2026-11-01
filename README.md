<p align="center">
  <a href="https://techniverse.net">
    <img src="https://assets.techniverse.net/f1/git/graphics/repo-techniverse-logo.png" alt="Techniverse Community" height="70" />
  </a>
</p>

<h1 align="center">TM-Server Docker</h1>

<h4 align="center">
  Ein vollständiges Docker-Setup für einen TrackMania Nations Forever-Server – inklusive Web-Verwaltung und Server-Controller
</h4>

<h6 align="center">
  <a href="https://www.cleveradmin.de">🏰 Website</a>
  ·
  <a href="https://techniverse.net">📰 Community</a>
  ·
  <a href="https://social.techniverse.net/@donnerwolke">🐘 Mastodon</a>
  ·
  <a href="https://matrix.to/#/#support:techniverse.net">💬 Support</a>
</h6>
<br><br>

## ✨ Übersicht

- **TrackMania Dedicated Server** – der eigentliche Spielserver für Internet- oder LAN-Betrieb
- **[XAseco](docs/xaseco.md)** – Server-Controller, der lokale Rekorde, Dedimania-Weltrekorde, Karma/Votes und eine Track-Jukebox direkt im Spielchat verwaltet
- **[AdminServ](docs/adminserv.md)** – Web-Oberfläche zur komfortablen Verwaltung und Konfiguration des Servers
- **[RemoteCP](docs/remotecp.md)** – alternative Web-Verwaltungsoberfläche mit eigenem Login- und Benutzersystem

Alle Komponenten laufen in einem einzigen Container und werden über Umgebungsvariablen konfiguriert.

> **Hinweis:** Dieses Projekt ist ein Fork von [lduriez/tmserver-docker](https://github.com/lduriez/tmserver-docker?tab=readme-ov-file).

Der Server unterstützt sowohl den **Internet-Dedicated-Modus** (Standard) als auch den **LAN-Dedicated-Modus**.

## ⚠️ PHP 8 – bitte lesen (ab v1.4.0)

Seit **v1.4.0** basiert das Image auf **Debian 13 (Trixie) mit PHP 8.4**. PHP 7.4 ist seit 2022 ohne Sicherheitsupdates und von kritischen Lücken wie *PHP2Shell* (CVE-2026-109618, CVE-2026-109619) betroffen – deshalb habe ich den Umstieg vorgenommen.

AdminServ, RemoteCP und XAseco stammen allerdings aus PHP-5-Zeiten. Damit sie unter PHP 8 laufen, patcht der Container sie beim Start automatisch (PHP-4-Konstruktoren, veraltete Syntax, statische Aufrufe und einige bekannte Laufzeitfehler). Die Anpassungen sind idempotent und greifen auch bei bestehenden Volumes.

Ich habe die gängigen Funktionen getestet, aber **es kann durchaus noch zu Fehlern kommen** – vor allem in selten genutzten Plugins oder Menüs. Wenn dir etwas auffällt (weiße Seite, HTTP 500, XAseco-Absturz, Funktion ohne Wirkung), eröffne bitte ein [Issue](https://git.techniverse.net/scriptos/tmserver-docker/issues) und gib möglichst an:

- was du gemacht hast (Seite/Plugin/Chat-Befehl) und ungefähr wann,
- die passende Meldung aus `docker logs tmserver`, dem Apache-Log (`docker exec tmserver tail -n 50 /var/log/apache2/error.log`), `data/xaseco/aseco.log` oder `data/controlpanel/remotecp/cache/errors.log`.

Ich schaue mir das dann an. Wer PHP 7.4 behalten möchte, bleibt vorerst beim Image-Tag `1.3.3`.

## 🚀 Schnellstart

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

## 📚 Dokumentation

Die vollständige Dokumentation befindet sich im Ordner [`docs/`](docs/README.md):

- [Schnellstart](docs/schnellstart.md) – Erste Schritte und minimale Konfiguration
- [Konfiguration](docs/konfiguration.md) – Persistente Serverkonfiguration (dedicated_cfg.txt)
- [Umgebungsvariablen](docs/umgebungsvariablen.md) – Alle verfügbaren Umgebungsvariablen
- [Server-Modi](docs/server-modi.md) – LAN- und Internet-Dedicated-Modus
- [AdminServ](docs/adminserv.md) – Einrichtung der Server-Verwaltungsoberfläche
- [RemoteCP](docs/remotecp.md) – Alternative Server-Verwaltungsoberfläche
- [XAseco](docs/xaseco.md) – Server-Controller für Rekorde, Karma und Jukebox
- [IP-Watcher](docs/ip-watcher.md) – Automatischer Neustart bei IP-Wechsel
- [Ports](docs/ports.md) – Freigegebene Ports und deren Verwendung
- [Update](docs/update.md) – Bestehende Installation aktualisieren

## 🙏 Danksagung

Ein herzliches Dankeschön an **[Thomas](https://retronerd.at)** – für seine tatkräftige Unterstützung, sein wertvolles Wissen und seine Mitwirkung an diesem Projekt. Ohne ihn wäre dieses Projekt nicht das, was es heute ist!

## 🔄 Spiegelung

Dieses Repository wird von **Gitea** auf **GitHub** gespiegelt. Das Master-Repository befindet sich auf Gitea:

- **Gitea (Master):** [git.techniverse.net/scriptos/tmserver-docker](https://git.techniverse.net/scriptos/tmserver-docker.git)
- **GitHub (Spiegel):** [github.com/pscriptos/tmserver-docker](https://github.com/pscriptos/tmserver-docker.git)


<br><br>
<p align="center">
  <img src="https://assets.techniverse.net/f1/git/graphics/gray0-catonline.svg" alt="">
</p>

<p align="center">
  <sub>
     © Patrick Asmus · Techniverse Network · <a href="./LICENSE">Lizenz</a>
  </sub>
</p>