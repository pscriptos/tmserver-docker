# Freigegebene Ports

| Port | Protokoll | Beschreibung |
|------|-----------|-------------|
| 2350 | TCP | Gameserver-Port |
| 2350 | UDP | Gameserver-Port |
| 3450 | TCP | P2P-Gameserver-Port |
| 5000 | TCP | XML-RPC-Port (interne Kommunikation) |
| 80 | TCP | Server-Verwaltungsoberfläche (AdminServ) |

## Minimale Port-Freigabe

Für den reinen Spielbetrieb ohne Verwaltungsoberfläche reichen die Ports 2350 und 3450:

```bash
docker run -d \
  --env-file .env \
  -p 2350:2350/tcp \
  -p 2350:2350/udp \
  -p 3450:3450/tcp \
  -v ./data/GameData:/opt/tmserver/GameData \
  --name tmserver tmserver:latest
```

> **Hinweis:** Port 5000 (XML-RPC) wird intern von AdminServ verwendet und muss in der Regel nicht nach außen freigegeben werden.
