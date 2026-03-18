#!/bin/sh

echo "Starting apache server"
service apache2 start

CONFIG="/opt/tmserver/GameData/Config/dedicated_cfg.txt"

echo "Setting ENV/ARG variables"
sed -i "s/<password>SuperAdmin/<password>${SERVER_SA_PASSWORD}/" "$CONFIG"
sed -i "s/<password>Admin/<password>${SERVER_ADM_PASSWORD}/" "$CONFIG"
sed -i "s/<name></<name>${SERVER_NAME}</" "$CONFIG"
sed -i "s/<comment></<comment>${SERVER_DESC}</" "$CONFIG"
sed -i "s/<xmlrpc_allowremote>False/<xmlrpc_allowremote>True/" "$CONFIG"

# Bestimme Server-Modus (Standard: internet)
SERVER_MODE="${SERVER_MODE:-internet}"

if [ "$SERVER_MODE" = "internet" ]; then
    echo "Configuring Internet-Dedicated mode"
    if [ -z "$SERVER_LOGIN" ] || [ -z "$SERVER_VALIDATION_KEY" ]; then
        echo "ERROR: SERVER_LOGIN and SERVER_VALIDATION_KEY are required for Internet-Dedicated mode."
        echo "Set SERVER_MODE=lan to start in LAN mode, or provide the required variables."
        exit 1
    fi
    sed -i "s|<login></login>|<login>${SERVER_LOGIN}</login>|" "$CONFIG"
    sed -i "s|<validation_key></validation_key>|<validation_key>${SERVER_VALIDATION_KEY}</validation_key>|" "$CONFIG"
    LAUNCH_MODE="/internet"
else
    echo "Configuring LAN-Dedicated mode"
    LAUNCH_MODE="/lan"
fi

echo "Server config dedicated_cfg.txt is"
cat "$CONFIG"

echo "Launching Server in ${SERVER_MODE} mode"
exec ./TrackmaniaServer /dedicated_cfg=dedicated_cfg.txt /game_settings=MatchSettings/custom_game_settings.txt /nodaemon ${LAUNCH_MODE}
