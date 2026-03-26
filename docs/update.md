# Update-Anleitung

Diese Anleitung beschreibt, wie du eine **bestehende Installation** auf den neuesten Stand bringst – ohne Daten zu verlieren und ohne alles neu aufsetzen zu müssen.

> **Hinweis:** Alle persistenten Daten (Konfiguration, Tracks, Datenbanken, Logs) liegen im Ordner `./data/` und werden bei einem Update nicht berührt.

---

## 1. Repository aktualisieren

Wechsle in den Projektordner und lade die neuesten Änderungen:

```bash
git pull
```

Damit werden aktualisierte Konfigurationsdateien, Skripte und Dokumentation aus dem Repository übernommen.

---

## 2. Neue Umgebungsvariablen prüfen

Mit neuen Versionen können neue Variablen in der `.env.example` hinzugekommen sein. Deine persönliche `.env`-Datei wird dabei **nicht überschrieben** – du musst neue Variablen manuell nachtragen.

Vergleiche `.env.example` mit deiner `.env`, um fehlende Einträge zu finden:

```bash
diff .env.example .env
```

Zeilen, die in `.env.example` vorhanden sind, aber nicht in deiner `.env`, erscheinen mit `<` am Anfang. Diese solltest du in deine `.env` übernehmen und die Werte anpassen.

> **Tipp:** Neue Variablen haben in der Regel sinnvolle Standardwerte, die du oft einfach übernehmen kannst. Achte nur auf sicherheitsrelevante Werte wie Passwörter.

---

## 3. Docker Image aktualisieren

Lade das neueste Image aus der Registry:

```bash
docker compose pull
```

---

## 4. Container neu starten

Starte die Container mit dem neuen Image neu. Docker Compose erkennt automatisch, ob ein Rebuild nötig ist:

```bash
docker compose up -d
```

> **Hinweis:** Wenn sich die `docker-compose.yml` geändert hat (z.B. neue Services oder geänderte Konfiguration), werden betroffene Container automatisch neu erstellt. Deine Daten in `./data/` bleiben dabei vollständig erhalten.

---

## Zusammenfassung

```bash
# Im Projektordner ausführen:
git pull
docker compose pull
docker compose up -d
```

Das war's – der Server läuft jetzt auf dem neuesten Stand.

---

## Was passiert mit meinen Daten?

| Ordner | Inhalt | Beim Update |
|--------|--------|-------------|
| `./data/gamedata/` | TM-Server-Daten, Konfiguration, Tracks | Bleibt erhalten |
| `./data/controlpanel/` | AdminServ- und RemoteCP-Daten | Bleibt erhalten |
| `./data/xaseco/` | XAseco-Konfiguration und Logs | Bleibt erhalten |
| `./data/mariadb/` | Datenbankdateien | Bleibt erhalten |
| `.env` | Deine Umgebungsvariablen | Wird nicht überschrieben |

---

## Häufige Situationen

### Neue Umgebungsvariable hat keinen Effekt

Einige Variablen (z.B. `SERVER_SA_PASSWORD`) werden nur beim **ersten Start** in die `dedicated_cfg.txt` geschrieben. Falls du eine neue Variable nachträglich setzen möchtest, kannst du das erzwingen:

```bash
# In der .env setzen:
FORCE_CONFIG_UPDATE=true
```

Dann Container neu starten. Danach unbedingt wieder auf `false` setzen, damit manuelle Änderungen erhalten bleiben. Weitere Details unter [Konfiguration](konfiguration.md).

### Welches Image-Tag wird verwendet?

In der `docker-compose.yml` ist das Image-Tag angegeben (z.B. `1.3.1` oder `latest`). Du kannst auf `latest` umstellen, um immer automatisch das neueste Image zu bekommen:

```yaml
image: git.techniverse.net/scriptos/trackmania-server:latest
```

Alle verfügbaren Tags findest du in der [Container-Registry](https://git.techniverse.net/scriptos/-/packages/container/trackmania-server/).
