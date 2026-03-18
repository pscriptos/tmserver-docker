# tmserver-docker

Trackmania Nations Forever Docker Server

> **Hinweis:** Dieses Projekt ist ein Fork von [lduriez/tmserver-docker](https://github.com/lduriez/tmserver-docker?tab=readme-ov-file).

Das Docker-Image ist auf Docker Hub verfügbar: [lduriez/tmserver](https://hub.docker.com/r/lduriez/tmserver)

Derzeit ist nur der LAN-Dedicated-Modus aktiviert (Internet-Dedicated wird in einer zukünftigen Version hinzugefügt).

Die Server-Verwaltungsoberfläche basiert auf [AdminServ](https://github.com/Chris92de/AdminServ).

## Starten

In einer Docker-Umgebung einfach folgenden Befehl ausführen:

```bash
docker run -d -p 2350:2350 -p 3450:3450 -p 80:80 --name tm-server lduriez/tmserver
```

Über Umgebungsvariablen können die Standardwerte angepasst werden: [Umgebungsvariablen](#umgebungsvariablen)

### Server-Verwaltungsoberfläche einrichten

Rufe `http:<host-server-des-containers>` auf und starte die Konfiguration, indem du ein Passwort deiner Wahl festlegst.
Dieses Passwort wird als AdminServ-Passwort für die Konfiguration (TM-Server hinzufügen) verwendet.

Trage anschließend die TM-Server-Informationen ein (die Standardwerte können beibehalten werden). Stelle sicher, dass `Address` auf `localhost` gesetzt ist, um den eingebetteten Server zu verwalten.

Nach dem Speichern kannst du über den Button „Servers" zur Serverliste navigieren und über den Button „Back" zur Verwaltungsübersicht gelangen.

Du solltest den hinzugefügten Server sehen. Im oberen Banner kannst du zur Verwaltungsumgebung wechseln.
Wähle den Server aus, den du verwalten möchtest, die gewünschte Admin-Stufe und gib das zugehörige Passwort ein.

Standardmäßig ist das `SuperAdmin`-Passwort `SuperAdmin`, das `Admin`-Passwort `Admin` und das `User`-Passwort `User`. (Die Admin-Stufen können in den Konfigurationseinstellungen unter `http:<host-server-des-containers>/config` geändert werden.)

Herzlichen Glückwunsch – du kannst jetzt deinen TM-Server verwalten.

Viel Spaß beim Spielen!

## Freigegebene Ports

* 2350/tcp – Gameserver-Port
* 2350/udp – Gameserver-Port
* 3450/tcp – P2P-Gameserver-Port
* 80/tcp – Port der Server-Verwaltungsoberfläche

## Umgebungsvariablen

* `SERVER_NAME` – Name deines Servers (Standard: `Trackmania Server`)
* `SERVER_DESC` – Beschreibung deines Servers (Standard: `This is a Trackmania Server`)
* `SERVER_SA_PASSWORD` – SuperAdmin-Verwaltungspasswort (Standard: `SuperAdmin`)
* `SERVER_ADM_PASSWORD` – Admin-Verwaltungspasswort (Standard: `Admin`)

## Commit-Konvention

Format: `<typ>(<bereich>): <beschreibung>`

### Typ

* `build` – Änderungen am Build-System oder an externen Abhängigkeiten (npm, make …)
* `ci` – Änderungen an CI-Konfigurationsdateien und -Skripten (Travis, Ansible, BrowserStack …)
* `feat` – Hinzufügen eines neuen Features
* `fix` – Behebung eines Fehlers
* `perf` – Verbesserung der Performance
* `refactor` – Änderung, die weder ein neues Feature noch eine Performance-Verbesserung bringt
* `style` – Änderung ohne funktionale oder semantische Auswirkung (Einrückung, Formatierung, Leerzeichen, Umbenennung einer Variable …)
* `docs` – Erstellung oder Aktualisierung von Dokumentation
* `test` – Hinzufügen oder Ändern von Tests
* `revert` – Einen vorherigen Commit rückgängig machen (Format: `revert <Betreff des rückgängig gemachten Commits> <Hash>`)

### Beschreibung

* `add` – Hinzufügen
* `change` – Ändern
* `update` – Aktualisieren
* `remove` – Entfernen

[Quelle](https://buzut.net/git-bien-nommer-ses-commits/)

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
