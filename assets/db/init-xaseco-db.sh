#!/bin/bash
# ============================================================
# MariaDB Init-Script: XAseco-Datenbank erstellen
# ============================================================
# Wird automatisch beim ersten Start des MariaDB-Containers
# ausgefuehrt (via /docker-entrypoint-initdb.d/).
# Erstellt Datenbank und Benutzer fuer XAseco, sofern die
# entsprechenden Umgebungsvariablen gesetzt sind.
# ============================================================

XASECO_DB_NAME="${XASECO_DB_NAME:-xaseco}"
XASECO_DB_USER="${XASECO_DB_USER:-xaseco}"
XASECO_DB_PASSWORD="${XASECO_DB_PASSWORD:-}"

if [ -z "$XASECO_DB_PASSWORD" ]; then
    echo "HINWEIS: XASECO_DB_PASSWORD nicht gesetzt – ueberspringe XAseco-DB-Erstellung."
    exit 0
fi

echo "Erstelle XAseco-Datenbank '${XASECO_DB_NAME}' und Benutzer '${XASECO_DB_USER}'..."

mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" <<-EOSQL
    CREATE DATABASE IF NOT EXISTS \`${XASECO_DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    CREATE USER IF NOT EXISTS '${XASECO_DB_USER}'@'%' IDENTIFIED BY '${XASECO_DB_PASSWORD}';
    GRANT ALL PRIVILEGES ON \`${XASECO_DB_NAME}\`.* TO '${XASECO_DB_USER}'@'%';
    FLUSH PRIVILEGES;
EOSQL

echo "XAseco-Datenbank erfolgreich erstellt."
