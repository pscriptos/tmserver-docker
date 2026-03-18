# Umgebungsvariablen

Alle Umgebungsvariablen können beim Start des Containers über `-e` oder in der `docker-compose.yml` gesetzt werden.

## Allgemeine Einstellungen

| Variable | Beschreibung | Standard |
|----------|-------------|----------|
| `SERVER_NAME` | Name des Servers | `Trackmania Server` |
| `SERVER_DESC` | Beschreibung des Servers | `This is a Trackmania Server` |
| `SERVER_SA_PASSWORD` | SuperAdmin-Verwaltungspasswort | `SuperAdmin` |
| `SERVER_ADM_PASSWORD` | Admin-Verwaltungspasswort | `Admin` |

## Server-Modus

| Variable | Beschreibung | Standard |
|----------|-------------|----------|
| `SERVER_MODE` | Server-Modus (`internet` oder `lan`) | `internet` |
| `SERVER_LOGIN` | Masterserver-Login (nur Internet-Modus) | *(leer)* |
| `SERVER_VALIDATION_KEY` | Masterserver-Validierungsschlüssel (nur Internet-Modus) | *(leer)* |

> **Wichtig:** Im Internet-Modus müssen `SERVER_LOGIN` und `SERVER_VALIDATION_KEY` gesetzt sein, andernfalls startet der Server nicht.

## Beispiel

```bash
docker run -d \
  -e SERVER_NAME="Mein Server" \
  -e SERVER_DESC="Ein toller Server" \
  -e SERVER_SA_PASSWORD="GeheimSA" \
  -e SERVER_ADM_PASSWORD="GeheimAdmin" \
  -e SERVER_MODE=internet \
  -e SERVER_LOGIN=mein_login \
  -e SERVER_VALIDATION_KEY=mein_key \
  -p 2350:2350/tcp \
  -p 2350:2350/udp \
  -p 3450:3450/tcp \
  -p 80:80/tcp \
  --name tm-server lduriez/tmserver
```
