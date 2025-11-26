# ============================================================================
# SCRIPT 2 : deploy_minecraft.sh
# Description : Déploiement d'un serveur Minecraft avec configuration
# Usage : sudo ./deploy_minecraft.sh <nom> <port> <memoire_min> <memoire_max> <max_players> <gamemode>
# Exemple : sudo ./deploy_minecraft.sh survival01 25565 1G 2G 20 survival
# ============================================================================

#!/bin/bash

# Récupération des paramètres
SERVER_NAME=$1
PORT=$2
MEMORY_MIN=$3
MEMORY_MAX=$4
MAX_PLAYERS=$5
GAMEMODE=$6

# Vérification des paramètres
if [ -z "$SERVER_NAME" ] || [ -z "$PORT" ] || [ -z "$MEMORY_MIN" ] || [ -z "$MEMORY_MAX" ] || [ -z "$MAX_PLAYERS" ] || [ -z "$GAMEMODE" ]; then
    echo "Usage: $0 <nom> <port> <memoire_min> <memoire_max> <max_players> <gamemode>"
    echo "Exemple: $0 survival01 25565 1G 2G 20 survival"
    exit 1
fi

echo "=== Déploiement du serveur $SERVER_NAME ==="

echo "Configuration:"
echo "  - Port: $PORT"
echo "  - Mémoire: $MEMORY_MIN à $MEMORY_MAX"
echo "  - Joueurs max: $MAX_PLAYERS"
echo "  - Mode de jeu: $GAMEMODE"
echo ""

echo "=== Création de l'utilisateur système $SERVER_NAME ==="
useradd --system --shell /bin/bash --home-dir /opt/gameservers/$SERVER_NAME --create-home $SERVER_NAME

echo "=== Création des répertoires du serveur ==="
mkdir -p /opt/gameservers/$SERVER_NAME/server
mkdir -p /opt/gameservers/$SERVER_NAME/backups
chown -R $SERVER_NAME:$SERVER_NAME /opt/gameservers/$SERVER_NAME
chmod 750 /opt/gameservers/$SERVER_NAME

echo "=== Téléchargement du JAR Minecraft (version 1.20.1) ==="
cd /opt/gameservers/$SERVER_NAME/server
wget -q -O server.jar https://piston-data.mojang.com/v1/objects/84194a2f286ef7c14ed7ce0090dba59902951553/server.jar
chown $SERVER_NAME:$SERVER_NAME server.jar

echo "=== Acceptation de l'EULA ==="
echo "eula=true" > eula.txt
chown $SERVER_NAME:$SERVER_NAME eula.txt

echo "=== Génération du fichier server.properties ==="
cat > server.properties << EOF
# Configuration générée automatiquement pour $SERVER_NAME
server-port=$PORT
max-players=$MAX_PLAYERS
gamemode=$GAMEMODE
difficulty=normal
view-distance=10
pvp=true
enable-command-block=false
spawn-protection=16
motd=Serveur Minecraft $SERVER_NAME
online-mode=true
EOF
chown $SERVER_NAME:$SERVER_NAME server.properties

echo "=== Création du service systemd ==="
cat > /etc/systemd/system/minecraft-$SERVER_NAME.service << EOF
[Unit]
Description=Minecraft Server - $SERVER_NAME
After=network.target

[Service]
Type=simple
User=$SERVER_NAME
WorkingDirectory=/opt/gameservers/$SERVER_NAME/server
ExecStart=/usr/bin/java -Xms$MEMORY_MIN -Xmx$MEMORY_MAX -jar server.jar nogui
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

echo "=== Activation et démarrage du service ==="
systemctl daemon-reload
systemctl enable minecraft-$SERVER_NAME.service
systemctl start minecraft-$SERVER_NAME.service

echo ""
echo "✓ Serveur $SERVER_NAME déployé avec succès !"
echo "  - Service: minecraft-$SERVER_NAME"
echo "  - Port: $PORT"
echo "  - Statut: systemctl status minecraft-$SERVER_NAME"
