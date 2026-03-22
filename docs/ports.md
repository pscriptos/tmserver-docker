# Freigegebene Ports

| Port | Protokoll | Beschreibung |
|------|-----------|-------------|
| 2350 | TCP | Gameserver-Port |
| 2350 | UDP | Gameserver-Port |
| 3450 | TCP | P2P-Gameserver-Port |
| 5000 | TCP | XML-RPC-Port (nur containerintern, nicht nach außen freigegeben) |
| 80 | TCP | Server-Verwaltungsoberflächen (AdminServ + RemoteCP) |

## Minimale Port-Freigabe

Für den reinen Spielbetrieb ohne Verwaltungsoberfläche reichen die Ports 2350 und 3450:

```bash
docker run -d \
  --env-file .env \
  -p 2350:2350/tcp \
  -p 2350:2350/udp \
  -p 3450:3450/tcp \
  -v ./data/gamedata:/opt/tmserver/GameData \
  -v ./data/xaseco:/opt/tmserver/xaseco \
  --name tmserver git.techniverse.net/scriptos/trackmania-server:latest
```

> **Hinweis:** Port 5000 (XML-RPC) wird containerintern von AdminServ, RemoteCP und XAseco verwendet und ist standardmäßig **nicht** nach außen freigegeben.
>
> Falls du den XML-RPC-Port extern benötigst (z. B. für ein externes Tool außerhalb des Containers), kannst du ihn nachträglich in der `docker-compose.yml` unter `ports:` ergänzen:
>
> ```yaml
> - "${SERVER_XMLRPC_PORT:-5000}:${SERVER_XMLRPC_PORT:-5000}/tcp"
> ```
>
> Bzw. bei `docker run`:
>
> ```bash
> -p 5000:5000/tcp
> ```
