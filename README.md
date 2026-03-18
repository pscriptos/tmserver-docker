# tmserver-docker

Trackmania Nations Forever Docker Server

> **Hinweis:** Dieses Projekt ist ein Fork von [lduriez/tmserver-docker](https://github.com/lduriez/tmserver-docker?tab=readme-ov-file).

Das Docker-Image ist auf Docker Hub verfügbar: [lduriez/tmserver](https://hub.docker.com/r/lduriez/tmserver)

Der Server unterstützt sowohl den **Internet-Dedicated-Modus** (Standard) als auch den **LAN-Dedicated-Modus**.

## Schnellstart

### Internet-Modus (Standard)

Voraussetzung: Ein Server-Account auf [players.trackmaniaforever.com](https://players.trackmaniaforever.com).

```bash
docker run -d \
  -p 2350:2350/tcp \
  -p 2350:2350/udp \
  -p 3450:3450/tcp \
  -p 80:80/tcp \
  -e SERVER_LOGIN=dein_login \
  -e SERVER_VALIDATION_KEY=dein_key \
  --name tm-server lduriez/tmserver
```

### LAN-Modus

```bash
docker run -d \
  -p 2350:2350/tcp \
  -p 2350:2350/udp \
  -p 3450:3450/tcp \
  -p 80:80/tcp \
  -e SERVER_MODE=lan \
  --name tm-server lduriez/tmserver
```

## Dokumentation

Die vollständige Dokumentation befindet sich im Ordner [`docs/`](docs/README.md):

- [Schnellstart](docs/schnellstart.md) – Erste Schritte und minimale Konfiguration
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
