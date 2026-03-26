# IP-Watcher

Der IP-Watcher ist ein Service (`tmserver-ip-watcher`), der automatisch die öffentliche IP des Hosts überwacht und den `tmserver`-Container neu startet, sobald sich die IP ändert.

## Hintergrund

Trackmania-Server registrieren sich beim Start mit ihrer aktuellen öffentlichen IP beim Nadeo-Masterserver. Bei dynamischen IP-Adressen kann sich diese IP jederzeit ändern – der Server bleibt dann unter der veralteten IP registriert und ist für Spieler nicht mehr erreichbar.

Der IP-Watcher erkennt solche IP-Wechsel automatisch und startet `tmserver` neu, sodass er sich mit der neuen IP beim Masterserver neu registriert.

## Funktion

Der Watcher läuft als eigener Docker-Container und:

1. Prüft regelmäßig die ausgehende öffentliche IP (identisch mit der IP, die auch `tmserver` nach außen verwendet)
2. Erkennt Abweichungen zur zuletzt bekannten IP
3. Startet `tmserver` über den Docker-Socket automatisch neu

## Konfiguration

| Variable | Beschreibung | Standard |
|----------|-------------|----------|
| `IP_WATCHER_INTERVAL` | Prüfintervall in Sekunden | `300` (5 Minuten) |

## Deaktivieren

Um den IP-Watcher zu deaktivieren, kommentiere den `ip-watcher`-Service in der `docker-compose.yml` aus:

```yaml
# ip-watcher:
#   ...
```

## Sicherheitshinweis

Der IP-Watcher benötigt Zugriff auf den Docker-Socket (`/var/run/docker.sock`), um den `tmserver`-Container neu starten zu können. Dieser Zugriff ermöglicht volle Kontrolle über alle Docker-Container und -Images auf dem Host. Stelle sicher, dass der Host ausreichend abgesichert ist und der Zugriff auf den Docker-Socket auf vertrauenswürdige Dienste beschränkt bleibt.
